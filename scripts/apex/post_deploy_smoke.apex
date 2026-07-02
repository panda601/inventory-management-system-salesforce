System.debug('INV_SUMMARY=' + JSON.serialize(InventoryDashboardController.getInventorySummary()));
System.debug('ADMIN_SUMMARY=' + JSON.serialize(InventoryDashboardController.getAdminDashboardSummary()));
System.debug('SALES_SUMMARY=' + JSON.serialize(InventoryDashboardController.getSalesSummary()));
System.debug('RETURN_COUNT=' + InventoryController.getReturnRequests().size());
System.debug('TXN_COUNT=' + InventoryController.getRecentTransactions().size());
System.debug('SO_COUNT=' + InventoryController.getRecentSalesOrders().size());
