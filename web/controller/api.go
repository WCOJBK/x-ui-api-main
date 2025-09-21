package controller

import (
	"x-ui/web/service"

	"github.com/gin-gonic/gin"
)

type APIController struct {
	BaseController
	inboundController     *InboundController
	outboundController    *OutboundController
	routingController     *RoutingController
	subscriptionController *SubscriptionController
	Tgbot                 service.Tgbot
}

func NewAPIController(g *gin.RouterGroup) *APIController {
	a := &APIController{}
	a.initRouter(g)
	return a
}

func (a *APIController) initRouter(g *gin.RouterGroup) {
	apiGroup := g.Group("/panel/api")
	apiGroup.Use(a.checkLogin)

	// Create Enhanced API controllers - each handles its own routing
	a.inboundController = NewInboundController(apiGroup.Group("/inbounds"))
	a.outboundController = NewOutboundController(apiGroup.Group("/outbound"))
	a.routingController = NewRoutingController(apiGroup.Group("/routing"))
	a.subscriptionController = NewSubscriptionController(apiGroup.Group("/subscription"))
	
	// Additional API endpoints
	apiGroup.GET("/createbackup", a.createBackup)
}

func (a *APIController) createBackup(c *gin.Context) {
	a.Tgbot.SendBackupToAdmins()
}
