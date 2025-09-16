package controller

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"x-ui/database/model"
	"x-ui/web/service"
	"x-ui/web/session"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type InboundController struct {
	inboundService service.InboundService
	xrayService    service.XrayService
}

func NewInboundController(g *gin.RouterGroup) *InboundController {
	a := &InboundController{}
	a.initRouter(g)
	return a
}

func (a *InboundController) initRouter(g *gin.RouterGroup) {
	g = g.Group("/inbound")

	g.POST("/list", a.getInbounds)
	g.POST("/add", a.addInbound)
	g.POST("/del/:id", a.delInbound)
	g.POST("/update/:id", a.updateInbound)
	g.POST("/clientIps/:email", a.getClientIps)
	g.POST("/clearClientIps/:email", a.clearClientIps)
	g.POST("/addClient", a.addInboundClient)
	g.POST("/addClientAdvanced", a.addInboundClientAdvanced)  // 新增：高级客户端添加
	g.GET("/client/details/:email", a.getClientDetails)       // 新增：获取客户端详情
	g.POST("/client/update/:email", a.updateClientAdvanced)   // 新增：更新客户端高级设置
	g.POST("/:id/delClient/:clientId", a.delInboundClient)
	g.POST("/updateClient/:clientId", a.updateInboundClient)
	g.POST("/:id/resetClientTraffic/:email", a.resetClientTraffic)
	g.POST("/resetAllTraffics", a.resetAllTraffics)
	g.POST("/resetAllClientTraffics/:id", a.resetAllClientTraffics)
	g.POST("/delDepletedClients/:id", a.delDepletedClients)
	g.POST("/import", a.importInbound)
	g.POST("/onlines", a.onlines)
}

func (a *InboundController) getInbounds(c *gin.Context) {
	user := session.GetLoginUser(c)
	inbounds, err := a.inboundService.GetInbounds(user.Id)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.toasts.obtain"), err)
		return
	}
	jsonObj(c, inbounds, nil)
}

func (a *InboundController) getInbound(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "get"), err)
		return
	}
	inbound, err := a.inboundService.GetInbound(id)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.toasts.obtain"), err)
		return
	}
	jsonObj(c, inbound, nil)
}

func (a *InboundController) getClientTraffics(c *gin.Context) {
	email := c.Param("email")
	clientTraffics, err := a.inboundService.GetClientTrafficByEmail(email)
	if err != nil {
		jsonMsg(c, "Error getting traffics", err)
		return
	}
	jsonObj(c, clientTraffics, nil)
}

func (a *InboundController) getClientTrafficsById(c *gin.Context) {
	id := c.Param("id")
	clientTraffics, err := a.inboundService.GetClientTrafficByID(id)
	if err != nil {
		jsonMsg(c, "Error getting traffics", err)
		return
	}
	jsonObj(c, clientTraffics, nil)
}

func (a *InboundController) addInbound(c *gin.Context) {
	inbound := &model.Inbound{}
	err := c.ShouldBind(inbound)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.create"), err)
		return
	}
	user := session.GetLoginUser(c)
	inbound.UserId = user.Id
	if inbound.Listen == "" || inbound.Listen == "0.0.0.0" || inbound.Listen == "::" || inbound.Listen == "::0" {
		inbound.Tag = fmt.Sprintf("inbound-%v", inbound.Port)
	} else {
		inbound.Tag = fmt.Sprintf("inbound-%v:%v", inbound.Listen, inbound.Port)
	}

	needRestart := false
	inbound, needRestart, err = a.inboundService.AddInbound(inbound)
	jsonMsgObj(c, I18nWeb(c, "pages.inbounds.create"), inbound, err)
	if err == nil && needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) delInbound(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "delete"), err)
		return
	}
	needRestart := true
	needRestart, err = a.inboundService.DelInbound(id)
	jsonMsgObj(c, I18nWeb(c, "delete"), id, err)
	if err == nil && needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) updateInbound(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}
	inbound := &model.Inbound{
		Id: id,
	}
	err = c.ShouldBind(inbound)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}
	needRestart := true
	inbound, needRestart, err = a.inboundService.UpdateInbound(inbound)
	jsonMsgObj(c, I18nWeb(c, "pages.inbounds.update"), inbound, err)
	if err == nil && needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) getClientIps(c *gin.Context) {
	email := c.Param("email")

	ips, err := a.inboundService.GetInboundClientIps(email)
	if err != nil || ips == "" {
		jsonObj(c, "No IP Record", nil)
		return
	}

	jsonObj(c, ips, nil)
}

func (a *InboundController) clearClientIps(c *gin.Context) {
	email := c.Param("email")

	err := a.inboundService.ClearClientIps(email)
	if err != nil {
		jsonMsg(c, "Update", err)
		return
	}
	jsonMsg(c, "Log Cleared", nil)
}

func (a *InboundController) addInboundClient(c *gin.Context) {
	data := &model.Inbound{}
	err := c.ShouldBind(data)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}

	needRestart := true

	needRestart, err = a.inboundService.AddInboundClient(data)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	jsonMsg(c, "Client(s) added", nil)
	if needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) addInboundClientAdvanced(c *gin.Context) {
	type AddClientRequest struct {
		InboundId  int    `json:"inboundId" form:"inboundId"`
		Email      string `json:"email" form:"email" binding:"required"`
		UUID       string `json:"uuid" form:"uuid"`
		Password   string `json:"password" form:"password"`
		Flow       string `json:"flow" form:"flow"`
		LimitIP    int    `json:"limitIp" form:"limitIp"`
		TotalGB    int64  `json:"totalGB" form:"totalGB"`
		ExpiryTime int64  `json:"expiryTime" form:"expiryTime"`
		Enable     bool   `json:"enable" form:"enable"`
		TgID       int64  `json:"tgId" form:"tgId"`
		SubID      string `json:"subId" form:"subId"`
		Comment    string `json:"comment" form:"comment"`
		Reset      int    `json:"reset" form:"reset"`
	}

	var req AddClientRequest
	err := c.ShouldBind(&req)
	if err != nil {
		jsonMsg(c, "Invalid request data", err)
		return
	}

	// 如果没有提供SubID，生成一个唯一的
	if req.SubID == "" {
		req.SubID = generateSubID(req.Email)
	}

	// 如果没有提供UUID，生成一个
	if req.UUID == "" {
		req.UUID = generateUUID()
	}

	// 构建客户端配置
	client := model.Client{
		ID:         req.UUID,
		Email:      req.Email,
		Password:   req.Password,
		Flow:       req.Flow,
		LimitIP:    req.LimitIP,
		TotalGB:    req.TotalGB,
		ExpiryTime: req.ExpiryTime,
		Enable:     req.Enable,
		TgID:       req.TgID,
		SubID:      req.SubID,
		Comment:    req.Comment,
		Reset:      req.Reset,
	}

	needRestart, err := a.inboundService.AddInboundClientAdvanced(req.InboundId, &client)
	if err != nil {
		jsonMsg(c, "Failed to add client", err)
		return
	}

	// 返回客户端信息和订阅链接
	response := map[string]interface{}{
		"client": client,
		"subscription": map[string]string{
			"normalSub": generateSubURL(c.Request.Host, req.SubID),
			"jsonSub":   generateJsonSubURL(c.Request.Host, req.SubID),
		},
	}

	jsonObj(c, response, nil)
	if needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) delInboundClient(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}
	clientId := c.Param("clientId")

	needRestart := true

	needRestart, err = a.inboundService.DelInboundClient(id, clientId)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	jsonMsg(c, "Client deleted", nil)
	if needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) updateInboundClient(c *gin.Context) {
	clientId := c.Param("clientId")

	inbound := &model.Inbound{}
	err := c.ShouldBind(inbound)
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}

	needRestart := true

	needRestart, err = a.inboundService.UpdateInboundClient(inbound, clientId)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	jsonMsg(c, "Client updated", nil)
	if needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) resetClientTraffic(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}
	email := c.Param("email")

	needRestart, err := a.inboundService.ResetClientTraffic(id, email)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	jsonMsg(c, "Traffic has been reset", nil)
	if needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) resetAllTraffics(c *gin.Context) {
	err := a.inboundService.ResetAllTraffics()
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	} else {
		a.xrayService.SetToNeedRestart()
	}
	jsonMsg(c, "all traffic has been reset", nil)
}

func (a *InboundController) resetAllClientTraffics(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}

	err = a.inboundService.ResetAllClientTraffics(id)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	} else {
		a.xrayService.SetToNeedRestart()
	}
	jsonMsg(c, "All traffic from the client has been reset.", nil)
}

func (a *InboundController) importInbound(c *gin.Context) {
	inbound := &model.Inbound{}
	err := json.Unmarshal([]byte(c.PostForm("data")), inbound)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	user := session.GetLoginUser(c)
	inbound.Id = 0
	inbound.UserId = user.Id
	if inbound.Listen == "" || inbound.Listen == "0.0.0.0" || inbound.Listen == "::" || inbound.Listen == "::0" {
		inbound.Tag = fmt.Sprintf("inbound-%v", inbound.Port)
	} else {
		inbound.Tag = fmt.Sprintf("inbound-%v:%v", inbound.Listen, inbound.Port)
	}

	for index := range inbound.ClientStats {
		inbound.ClientStats[index].Id = 0
		inbound.ClientStats[index].Enable = true
	}

	needRestart := false
	inbound, needRestart, err = a.inboundService.AddInbound(inbound)
	jsonMsgObj(c, I18nWeb(c, "pages.inbounds.create"), inbound, err)
	if err == nil && needRestart {
		a.xrayService.SetToNeedRestart()
	}
}

func (a *InboundController) delDepletedClients(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		jsonMsg(c, I18nWeb(c, "pages.inbounds.update"), err)
		return
	}
	err = a.inboundService.DelDepletedClients(id)
	if err != nil {
		jsonMsg(c, "Something went wrong!", err)
		return
	}
	jsonMsg(c, "All depleted clients are deleted", nil)
}

func (a *InboundController) onlines(c *gin.Context) {
	jsonObj(c, a.inboundService.GetOnlineClients(), nil)
}

// 辅助函数
func generateSubID(email string) string {
	// 生成基于邮箱和时间戳的唯一SubID
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return fmt.Sprintf("%s-%s", strings.ReplaceAll(email, "@", "-"), hex.EncodeToString(bytes)[:8])
}

func generateUUID() string {
	return uuid.New().String()
}

func generateSubURL(host, subID string) string {
	return fmt.Sprintf("http://%s/sub/%s", host, subID)
}

func generateJsonSubURL(host, subID string) string {
	return fmt.Sprintf("http://%s/json/%s", host, subID)
}

// 获取客户端详细信息
func (a *InboundController) getClientDetails(c *gin.Context) {
	email := c.Param("email")
	if email == "" {
		jsonMsg(c, "Invalid email parameter", nil)
		return
	}

	clientTraffic, err := a.inboundService.GetClientTrafficByEmail(email)
	if err != nil {
		jsonMsg(c, "Client not found", err)
		return
	}

	// 获取客户端订阅链接
	response := map[string]interface{}{
		"traffic": clientTraffic,
		"subscription": map[string]string{
			"normalSub": generateSubURL(c.Request.Host, email), // 使用email作为临时SubID
			"jsonSub":   generateJsonSubURL(c.Request.Host, email),
		},
	}

	jsonObj(c, response, nil)
}

// 更新客户端高级设置
func (a *InboundController) updateClientAdvanced(c *gin.Context) {
	email := c.Param("email")
	if email == "" {
		jsonMsg(c, "Invalid email parameter", nil)
		return
	}

	type UpdateClientRequest struct {
		LimitIP    *int   `json:"limitIp,omitempty"`
		TotalGB    *int64 `json:"totalGB,omitempty"`
		ExpiryTime *int64 `json:"expiryTime,omitempty"`
		Enable     *bool  `json:"enable,omitempty"`
		TgID       *int64 `json:"tgId,omitempty"`
		SubID      string `json:"subId,omitempty"`
		Comment    string `json:"comment,omitempty"`
		Reset      *int   `json:"reset,omitempty"`
	}

	var req UpdateClientRequest
	err := c.ShouldBind(&req)
	if err != nil {
		jsonMsg(c, "Invalid request data", err)
		return
	}

	err = a.inboundService.UpdateClientAdvanced(email, &req)
	if err != nil {
		jsonMsg(c, "Failed to update client", err)
		return
	}

	jsonMsg(c, "Client updated successfully", nil)
}
