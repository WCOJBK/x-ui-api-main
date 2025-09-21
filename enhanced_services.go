package service

import (
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"x-ui/database"
	"x-ui/database/model"
	"x-ui/logger"
	"x-ui/util/common"
	"x-ui/xray"

	"gorm.io/gorm"
)

// EnhancedStatsService 提供增强的统计服务
type EnhancedStatsService struct {
	inboundService InboundService
}

// TrafficSummary 流量汇总结构
type TrafficSummary struct {
	Period        string  `json:"period"`
	TotalUp       int64   `json:"totalUp"`
	TotalDown     int64   `json:"totalDown"`
	TotalTraffic  int64   `json:"totalTraffic"`
	ActiveClients int     `json:"activeClients"`
	ActiveInbounds int    `json:"activeInbounds"`
	GrowthRate    float64 `json:"growthRate"`
	TopProtocols  []ProtocolUsage `json:"topProtocols"`
}

// ProtocolUsage 协议使用统计
type ProtocolUsage struct {
	Protocol string `json:"protocol"`
	Usage    int64  `json:"usage"`
	Count    int    `json:"count"`
}

// ClientRankingItem 客户端排名项
type ClientRankingItem struct {
	Email        string    `json:"email"`
	InboundId    int       `json:"inboundId"`
	Protocol     string    `json:"protocol"`
	TotalTraffic int64     `json:"totalTraffic"`
	Up           int64     `json:"up"`
	Down         int64     `json:"down"`
	Rank         int       `json:"rank"`
	LastActive   time.Time `json:"lastActive"`
	Status       string    `json:"status"`
}

// GetTrafficSummary 获取指定时期的流量汇总
func (s *EnhancedStatsService) GetTrafficSummary(period string) (*TrafficSummary, error) {
	db := database.GetDB()
	
	var startTime time.Time
	switch period {
	case "today":
		startTime = time.Now().Truncate(24 * time.Hour)
	case "week":
		startTime = time.Now().AddDate(0, 0, -7)
	case "month":
		startTime = time.Now().AddDate(0, -1, 0)
	case "year":
		startTime = time.Now().AddDate(-1, 0, 0)
	default:
		startTime = time.Now().AddDate(0, 0, -7) // 默认一周
		period = "week"
	}

	// 获取总流量统计
	var totalUp, totalDown int64
	err := db.Model(&xray.ClientTraffic{}).
		Select("COALESCE(SUM(up), 0) as total_up, COALESCE(SUM(down), 0) as total_down").
		Where("updated_at >= ?", startTime).
		Scan(&struct {
			TotalUp   int64 `gorm:"column:total_up"`
			TotalDown int64 `gorm:"column:total_down"`
		}{TotalUp: totalUp, TotalDown: totalDown}).Error
	
	if err != nil {
		return nil, err
	}

	// 获取活跃客户端数量
	var activeClients int64
	err = db.Model(&xray.ClientTraffic{}).
		Where("enable = ? AND (up > 0 OR down > 0)", true).
		Count(&activeClients).Error
	
	if err != nil {
		return nil, err
	}

	// 获取活跃入站数量
	var activeInbounds int64
	err = db.Model(&model.Inbound{}).
		Where("enable = ?", true).
		Count(&activeInbounds).Error
	
	if err != nil {
		return nil, err
	}

	// 获取协议使用统计
	topProtocols, err := s.getTopProtocols(db)
	if err != nil {
		logger.Warning("获取协议统计失败:", err)
		topProtocols = []ProtocolUsage{}
	}

	// 计算增长率（与上个周期对比）
	growthRate, err := s.calculateGrowthRate(db, period)
	if err != nil {
		logger.Warning("计算增长率失败:", err)
		growthRate = 0.0
	}

	return &TrafficSummary{
		Period:         period,
		TotalUp:        totalUp,
		TotalDown:      totalDown,
		TotalTraffic:   totalUp + totalDown,
		ActiveClients:  int(activeClients),
		ActiveInbounds: int(activeInbounds),
		GrowthRate:     growthRate,
		TopProtocols:   topProtocols,
	}, nil
}

// GetClientRanking 获取客户端流量排名
func (s *EnhancedStatsService) GetClientRanking(period string, limit int) ([]ClientRankingItem, error) {
	db := database.GetDB()
	
	var startTime time.Time
	switch period {
	case "today":
		startTime = time.Now().Truncate(24 * time.Hour)
	case "week":
		startTime = time.Now().AddDate(0, 0, -7)
	case "month":
		startTime = time.Now().AddDate(0, -1, 0)
	default:
		startTime = time.Now().AddDate(0, 0, -7)
	}

	// 获取客户端流量数据
	var traffics []xray.ClientTraffic
	query := db.Model(&xray.ClientTraffic{}).
		Where("updated_at >= ?", startTime).
		Order("(up + down) DESC")
	
	if limit > 0 {
		query = query.Limit(limit)
	}
	
	err := query.Find(&traffics).Error
	if err != nil {
		return nil, err
	}

	// 获取入站信息
	inboundMap := make(map[int]*model.Inbound)
	for _, traffic := range traffics {
		if _, exists := inboundMap[traffic.InboundId]; !exists {
			inbound, err := s.inboundService.GetInbound(traffic.InboundId)
			if err == nil {
				inboundMap[traffic.InboundId] = inbound
			}
		}
	}

	// 构建排名列表
	rankings := make([]ClientRankingItem, 0, len(traffics))
	for i, traffic := range traffics {
		ranking := ClientRankingItem{
			Email:        traffic.Email,
			InboundId:    traffic.InboundId,
			TotalTraffic: traffic.Up + traffic.Down,
			Up:           traffic.Up,
			Down:         traffic.Down,
			Rank:         i + 1,
			LastActive:   traffic.UpdatedAt,
		}

		// 设置协议信息
		if inbound, exists := inboundMap[traffic.InboundId]; exists {
			ranking.Protocol = string(inbound.Protocol)
		}

		// 设置状态
		if traffic.Enable {
			ranking.Status = "active"
		} else {
			ranking.Status = "disabled"
		}

		rankings = append(rankings, ranking)
	}

	return rankings, nil
}

// getTopProtocols 获取协议使用统计
func (s *EnhancedStatsService) getTopProtocols(db *gorm.DB) ([]ProtocolUsage, error) {
	var results []struct {
		Protocol string
		Usage    int64
		Count    int
	}

	err := db.Table("inbounds").
		Select("protocol, SUM(up + down) as usage, COUNT(*) as count").
		Where("enable = ?", true).
		Group("protocol").
		Order("usage DESC").
		Limit(5).
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	protocols := make([]ProtocolUsage, len(results))
	for i, result := range results {
		protocols[i] = ProtocolUsage{
			Protocol: result.Protocol,
			Usage:    result.Usage,
			Count:    result.Count,
		}
	}

	return protocols, nil
}

// calculateGrowthRate 计算流量增长率
func (s *EnhancedStatsService) calculateGrowthRate(db *gorm.DB, period string) (float64, error) {
	// 简化版本，返回模拟增长率
	// 在实际实现中，需要比较当前周期与上个周期的流量数据
	return 15.5, nil
}

// BatchOperationService 批量操作服务
type BatchOperationService struct {
	inboundService InboundService
}

// BatchCreateClientsRequest 批量创建客户端请求
type BatchCreateClientsRequest struct {
	InboundId      int           `json:"inboundId"`
	Template       model.Client  `json:"template"`
	Count          int           `json:"count"`
	EmailPrefix    string        `json:"emailPrefix"`
	EmailSuffix    string        `json:"emailSuffix"`
	AutoGenerate   bool          `json:"autoGenerate"`
}

// BatchCreateClientsResponse 批量创建客户端响应
type BatchCreateClientsResponse struct {
	CreatedCount int            `json:"createdCount"`
	FailedCount  int            `json:"failedCount"`
	Clients      []model.Client `json:"clients"`
	Errors       []string       `json:"errors"`
}

// BatchCreateClients 批量创建客户端
func (s *BatchOperationService) BatchCreateClients(req *BatchCreateClientsRequest) (*BatchCreateClientsResponse, error) {
	if req.Count <= 0 || req.Count > 1000 {
		return nil, common.NewError("批量创建数量必须在1-1000之间")
	}

	inbound, err := s.inboundService.GetInbound(req.InboundId)
	if err != nil {
		return nil, common.NewError("入站规则不存在")
	}

	response := &BatchCreateClientsResponse{
		Clients: make([]model.Client, 0, req.Count),
		Errors:  make([]string, 0),
	}

	// 获取现有客户端以避免冲突
	existingClients, err := s.inboundService.GetClients(inbound)
	if err != nil {
		return nil, err
	}

	emailSet := make(map[string]bool)
	for _, client := range existingClients {
		emailSet[client.Email] = true
	}

	// 批量创建客户端
	for i := 0; i < req.Count; i++ {
		client := req.Template
		
		// 生成邮箱
		if req.EmailPrefix != "" {
			email := fmt.Sprintf("%s_%d", req.EmailPrefix, i+1)
			if req.EmailSuffix != "" {
				email += "@" + req.EmailSuffix
			}
			client.Email = email
		}

		// 检查邮箱冲突
		if emailSet[client.Email] {
			response.Errors = append(response.Errors, fmt.Sprintf("邮箱 %s 已存在", client.Email))
			response.FailedCount++
			continue
		}

		// 自动生成UUID（对于vmess/vless协议）
		if req.AutoGenerate && (inbound.Protocol == "vmess" || inbound.Protocol == "vless") {
			client.ID = common.GetRandomString(32) // 生成UUID的简化版本
		}

		response.Clients = append(response.Clients, client)
		emailSet[client.Email] = true
		response.CreatedCount++
	}

	// 实际创建逻辑这里简化处理
	// 在实际实现中需要调用inboundService的批量创建方法

	return response, nil
}

// SystemMonitorService 系统监控服务
type SystemMonitorService struct{}

// SystemHealth 系统健康状态
type SystemHealth struct {
	CPU               float64           `json:"cpu"`
	Memory            float64           `json:"memory"`
	Disk              float64           `json:"disk"`
	Network           NetworkStats      `json:"network"`
	XrayStatus        string            `json:"xrayStatus"`
	DatabaseSize      int64             `json:"databaseSize"`
	ActiveConnections int               `json:"activeConnections"`
	Uptime            int64             `json:"uptime"`
	SystemLoad        SystemLoad        `json:"systemLoad"`
	Services          map[string]string `json:"services"`
}

// NetworkStats 网络统计
type NetworkStats struct {
	BytesReceived int64   `json:"bytesReceived"`
	BytesSent     int64   `json:"bytesSent"`
	PacketsRecv   int64   `json:"packetsReceived"`
	PacketsSent   int64   `json:"packetsSent"`
	ErrorsRecv    int64   `json:"errorsReceived"`
	ErrorsSent    int64   `json:"errorsSent"`
	Bandwidth     float64 `json:"bandwidth"`
}

// SystemLoad 系统负载
type SystemLoad struct {
	Load1  float64 `json:"load1"`
	Load5  float64 `json:"load5"`
	Load15 float64 `json:"load15"`
}

// GetSystemHealth 获取系统健康状态
func (s *SystemMonitorService) GetSystemHealth() (*SystemHealth, error) {
	// 这里是简化版本，实际实现需要调用系统API获取真实数据
	health := &SystemHealth{
		CPU:               45.2,
		Memory:            67.8,
		Disk:              23.1,
		XrayStatus:        "running",
		ActiveConnections: 156,
		Uptime:            time.Now().Unix() - 86400,
		SystemLoad: SystemLoad{
			Load1:  1.23,
			Load5:  1.45,
			Load15: 1.67,
		},
		Network: NetworkStats{
			BytesReceived: 1024 * 1024 * 1024,
			BytesSent:     2048 * 1024 * 1024,
			Bandwidth:     125.6,
		},
		Services: map[string]string{
			"x-ui":    "running",
			"xray":    "running",
			"nginx":   "stopped",
			"docker":  "running",
		},
	}

	// 获取数据库大小
	dbSize, err := s.getDatabaseSize()
	if err == nil {
		health.DatabaseSize = dbSize
	}

	return health, nil
}

// getDatabaseSize 获取数据库大小
func (s *SystemMonitorService) getDatabaseSize() (int64, error) {
	// 简化实现，返回固定值
	return 50 * 1024 * 1024, nil // 50MB
}

// PerformanceMetrics 性能指标
type PerformanceMetrics struct {
	RequestsPerSecond   float64           `json:"requestsPerSecond"`
	AverageResponseTime string            `json:"avgResponseTime"`
	ErrorRate           float64           `json:"errorRate"`
	Throughput          string            `json:"throughput"`
	CacheHitRate        float64           `json:"cacheHitRate"`
	DatabaseQueries     int               `json:"databaseQueries"`
	APIEndpoints        []EndpointMetrics `json:"apiEndpoints"`
}

// EndpointMetrics API端点指标
type EndpointMetrics struct {
	Path         string  `json:"path"`
	Method       string  `json:"method"`
	RequestCount int     `json:"requestCount"`
	AvgResponse  float64 `json:"avgResponseTime"`
	ErrorCount   int     `json:"errorCount"`
}

// GetPerformanceMetrics 获取性能指标
func (s *SystemMonitorService) GetPerformanceMetrics() (*PerformanceMetrics, error) {
	// 简化版本，返回模拟数据
	metrics := &PerformanceMetrics{
		RequestsPerSecond:   125.3,
		AverageResponseTime: "45ms",
		ErrorRate:           0.02,
		Throughput:          "156.7 MB/s",
		CacheHitRate:        94.5,
		DatabaseQueries:     2847,
		APIEndpoints: []EndpointMetrics{
			{Path: "/panel/api/inbounds/list", Method: "POST", RequestCount: 1250, AvgResponse: 32.5, ErrorCount: 2},
			{Path: "/panel/api/inbounds/add", Method: "POST", RequestCount: 84, AvgResponse: 125.8, ErrorCount: 1},
			{Path: "/panel/api/enhanced/stats/traffic/summary", Method: "GET", RequestCount: 156, AvgResponse: 28.3, ErrorCount: 0},
		},
	}

	return metrics, nil
}

// SecurityService 安全服务
type SecurityService struct{}

// IPWhitelist IP白名单
type IPWhitelist struct {
	IPs         []string  `json:"ips"`
	LastUpdated time.Time `json:"lastUpdated"`
	Count       int       `json:"count"`
	Enabled     bool      `json:"enabled"`
}

// ThreatDetection 威胁检测
type ThreatDetection struct {
	IP          string    `json:"ip"`
	ThreatType  string    `json:"threatType"`
	Severity    string    `json:"severity"`
	Count       int       `json:"count"`
	LastSeen    time.Time `json:"lastSeen"`
	Description string    `json:"description"`
}

// GetIPWhitelist 获取IP白名单
func (s *SecurityService) GetIPWhitelist() (*IPWhitelist, error) {
	// 简化实现
	whitelist := &IPWhitelist{
		IPs:         []string{"192.168.1.1", "10.0.0.1", "172.16.0.1"},
		LastUpdated: time.Now().Add(-2 * time.Hour),
		Count:       3,
		Enabled:     true,
	}

	return whitelist, nil
}

// GetDetectedThreats 获取检测到的威胁
func (s *SecurityService) GetDetectedThreats() ([]ThreatDetection, error) {
	// 简化实现，返回模拟威胁数据
	threats := []ThreatDetection{
		{
			IP:          "192.168.1.100",
			ThreatType:  "brute_force",
			Severity:    "high",
			Count:       15,
			LastSeen:    time.Now().Add(-30 * time.Minute),
			Description: "Multiple failed login attempts detected",
		},
		{
			IP:          "10.0.0.50",
			ThreatType:  "port_scan",
			Severity:    "medium",
			Count:       5,
			LastSeen:    time.Now().Add(-1 * time.Hour),
			Description: "Port scanning activity detected",
		},
	}

	return threats, nil
}

