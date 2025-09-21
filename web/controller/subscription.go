package controller

import (
	"strconv"
	"x-ui/web/service"
	"github.com/gin-gonic/gin"
)

type SubscriptionController struct {
	settingService service.SettingService
	inboundService service.InboundService
}

func NewSubscriptionController(g *gin.RouterGroup) *SubscriptionController {
	a := &SubscriptionController{}
	a.initRouter(g)
	return a
}

func (a *SubscriptionController) initRouter(g *gin.RouterGroup) {
	// Routes are handled directly on the group (no additional sub-group needed)
	g.POST("/settings/get", a.getSubSettings)
	g.POST("/settings/update", a.updateSubSettings)
	g.POST("/enable", a.enableSubscription)
	g.POST("/disable", a.disableSubscription)
	g.GET("/urls/:id", a.getSubscriptionUrls)
}

func (a *SubscriptionController) getSubSettings(c *gin.Context) {
	settings := make(map[string]interface{})
	
	// Get all subscription-related settings
	subEnable, _ := a.settingService.GetSubEnable()
	subListen, _ := a.settingService.GetSubListen()
	subPort, _ := a.settingService.GetSubPort()
	subPath, _ := a.settingService.GetSubPath()
	subJsonPath, _ := a.settingService.GetSubJsonPath()
	subDomain, _ := a.settingService.GetSubDomain()
	subCertFile, _ := a.settingService.GetSubCertFile()
	subKeyFile, _ := a.settingService.GetSubKeyFile()
	subUpdates, _ := a.settingService.GetSubUpdates()
	subEncrypt, _ := a.settingService.GetSubEncrypt()
	subShowInfo, _ := a.settingService.GetSubShowInfo()
	subURI, _ := a.settingService.GetSubURI()
	subJsonURI, _ := a.settingService.GetSubJsonURI()
	subJsonFragment, _ := a.settingService.GetSubJsonFragment()
	subJsonNoises, _ := a.settingService.GetSubJsonNoises()
	subJsonMux, _ := a.settingService.GetSubJsonMux()
	subJsonRules, _ := a.settingService.GetSubJsonRules()

	settings["enable"] = subEnable
	settings["listen"] = subListen
	settings["port"] = subPort
	settings["path"] = subPath
	settings["jsonPath"] = subJsonPath
	settings["domain"] = subDomain
	settings["certFile"] = subCertFile
	settings["keyFile"] = subKeyFile
	settings["updates"] = subUpdates
	settings["encrypt"] = subEncrypt
	settings["showInfo"] = subShowInfo
	settings["subURI"] = subURI
	settings["subJsonURI"] = subJsonURI
	settings["jsonFragment"] = subJsonFragment
	settings["jsonNoises"] = subJsonNoises
	settings["jsonMux"] = subJsonMux
	settings["jsonRules"] = subJsonRules

	jsonObj(c, settings, nil)
}

func (a *SubscriptionController) updateSubSettings(c *gin.Context) {
	jsonMsg(c, "Subscription settings update not implemented - use panel interface for configuration", nil)
}

func (a *SubscriptionController) enableSubscription(c *gin.Context) {
	jsonMsg(c, "Subscription enable/disable not implemented via API - use panel interface", nil)
}

func (a *SubscriptionController) disableSubscription(c *gin.Context) {
	jsonMsg(c, "Subscription enable/disable not implemented via API - use panel interface", nil)
}

func (a *SubscriptionController) getSubscriptionUrls(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		jsonMsg(c, "Invalid inbound ID", nil)
		return
	}

	inboundId, err := strconv.Atoi(id)
	if err != nil {
		jsonMsg(c, "Invalid inbound ID format", err)
		return
	}

	inbound, err := a.inboundService.GetInbound(inboundId)
	if err != nil {
		jsonMsg(c, "Failed to get inbound", err)
		return
	}

	host := c.Request.Host
	subPath, _ := a.settingService.GetSubPath()
	subJsonPath, _ := a.settingService.GetSubJsonPath()
	subDomain, _ := a.settingService.GetSubDomain()
	
	if subDomain != "" {
		host = subDomain
	}

	urls := map[string]string{
		"subscription": "http://" + host + subPath + inbound.Tag,
		"jsonSubscription": "http://" + host + subJsonPath + inbound.Tag,
	}

	jsonObj(c, urls, nil)
}
