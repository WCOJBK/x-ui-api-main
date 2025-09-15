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
	g = g.Group("/panel/api")
	g.Use(a.checkLogin)

	a.inboundController = NewInboundController(g.Group("/inbounds"))
	a.outboundController = NewOutboundController(g.Group("/outbounds"))
	a.routingController = NewRoutingController(g.Group("/routing"))
	a.subscriptionController = NewSubscriptionController(g.Group("/subscription"))

	inboundRoutes := []struct {
		Method  string
		Path    string
		Handler gin.HandlerFunc
	}{
		{"GET", "/createbackup", a.createBackup},
		{"GET", "/inbounds/list", a.inboundController.getInbounds},
		{"GET", "/inbounds/get/:id", a.inboundController.getInbound},
		{"GET", "/inbounds/getClientTraffics/:email", a.inboundController.getClientTraffics},
		{"GET", "/inbounds/getClientTrafficsById/:id", a.inboundController.getClientTrafficsById},
		{"GET", "/inbounds/client/details/:email", a.inboundController.getClientDetails},
		{"POST", "/inbounds/add", a.inboundController.addInbound},
		{"POST", "/inbounds/del/:id", a.inboundController.delInbound},
		{"POST", "/inbounds/update/:id", a.inboundController.updateInbound},
		{"POST", "/inbounds/clientIps/:email", a.inboundController.getClientIps},
		{"POST", "/inbounds/clearClientIps/:email", a.inboundController.clearClientIps},
		{"POST", "/inbounds/addClient", a.inboundController.addInboundClient},
		{"POST", "/inbounds/addClientAdvanced", a.inboundController.addInboundClientAdvanced},
		{"POST", "/inbounds/client/update/:email", a.inboundController.updateClientAdvanced},
		{"POST", "/inbounds/:id/delClient/:clientId", a.inboundController.delInboundClient},
		{"POST", "/inbounds/updateClient/:clientId", a.inboundController.updateInboundClient},
		{"POST", "/inbounds/:id/resetClientTraffic/:email", a.inboundController.resetClientTraffic},
		{"POST", "/inbounds/resetAllTraffics", a.inboundController.resetAllTraffics},
		{"POST", "/inbounds/resetAllClientTraffics/:id", a.inboundController.resetAllClientTraffics},
		{"POST", "/inbounds/delDepletedClients/:id", a.inboundController.delDepletedClients},
		{"POST", "/inbounds/onlines", a.inboundController.onlines},
	}

	outboundRoutes := []struct {
		Method  string
		Path    string
		Handler gin.HandlerFunc
	}{
		{"POST", "/outbounds/list", a.outboundController.getOutbounds},
		{"POST", "/outbounds/add", a.outboundController.addOutbound},
		{"POST", "/outbounds/del/:tag", a.outboundController.delOutbound},
		{"POST", "/outbounds/update/:tag", a.outboundController.updateOutbound},
		{"POST", "/outbounds/resetTraffic/:tag", a.outboundController.resetTraffic},
		{"POST", "/outbounds/resetAllTraffics", a.outboundController.resetAllTraffics},
	}

	routingRoutes := []struct {
		Method  string
		Path    string
		Handler gin.HandlerFunc
	}{
		{"POST", "/routing/get", a.routingController.getRouting},
		{"POST", "/routing/update", a.routingController.updateRouting},
		{"POST", "/routing/rule/add", a.routingController.addRule},
		{"POST", "/routing/rule/del", a.routingController.deleteRule},
		{"POST", "/routing/rule/update", a.routingController.updateRule},
	}

	subscriptionRoutes := []struct {
		Method  string
		Path    string
		Handler gin.HandlerFunc
	}{
		{"POST", "/subscription/settings/get", a.subscriptionController.getSubSettings},
		{"POST", "/subscription/settings/update", a.subscriptionController.updateSubSettings},
		{"POST", "/subscription/enable", a.subscriptionController.enableSubscription},
		{"POST", "/subscription/disable", a.subscriptionController.disableSubscription},
		{"GET", "/subscription/urls/:id", a.subscriptionController.getSubscriptionUrls},
	}

	for _, route := range inboundRoutes {
		g.Handle(route.Method, route.Path, route.Handler)
	}

	for _, route := range outboundRoutes {
		g.Handle(route.Method, route.Path, route.Handler)
	}

	for _, route := range routingRoutes {
		g.Handle(route.Method, route.Path, route.Handler)
	}

	for _, route := range subscriptionRoutes {
		g.Handle(route.Method, route.Path, route.Handler)
	}
}

func (a *APIController) createBackup(c *gin.Context) {
	a.Tgbot.SendBackupToAdmins()
}
