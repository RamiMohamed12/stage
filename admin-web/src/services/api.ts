  // TODO: These endpoints need to be implemented in the backend
  // Temporarily using mock data for development

  async getDeclarations(
    page: number = 1,
    limit: number = 10,
    status?: string,
    search?: string
  ): Promise<{ declarations: DeclarationWithDetails[]; total: number; page: number; totalPages: number }> {
    // TODO: Implement in backend - for now return mock data
    console.warn('getDeclarations: This endpoint needs to be implemented in the backend');
    return {
      declarations: [],
      total: 0,
      page: 1,
      totalPages: 1
    };
  }

  async getDeclarationById(declarationId: number): Promise<DeclarationWithDetails> {
    // TODO: Implement in backend
    console.warn('getDeclarationById: This endpoint needs to be implemented in the backend');
    throw new Error('Endpoint not implemented in backend yet');
  }

  async getDeclarationDocuments(declarationId: number): Promise<DeclarationDocument[]> {
    // TODO: Implement in backend
    console.warn('getDeclarationDocuments: This endpoint needs to be implemented in the backend');
    return [];
  }

  async getDashboardStats(): Promise<AdminStats> {
    // TODO: Implement in backend - for now return mock data
    console.warn('getDashboardStats: This endpoint needs to be implemented in the backend');
    return {
      totalDeclarations: 156,
      pendingDeclarations: 23,
      approvedDeclarations: 120,
      rejectedDeclarations: 13,
      pendingDocuments: 45,
      totalDocuments: 312
    };
  }

  async getCurrentUser(): Promise<User> {
    // TODO: Implement in backend
    console.warn('getCurrentUser: This endpoint needs to be implemented in the backend');
    throw new Error('Endpoint not implemented in backend yet');
  }

  // Notification System - Now implemented in backend
  async sendNotification(userId: number, title: string, body: string, type?: string, relatedId?: number): Promise<void> {
    await this.api.post('/notifications/send', {
      user_id: userId,
      title,
      body,
      type: type || 'general',
      related_id: relatedId
    });
  }

  async getAllNotifications(limit: number = 100, offset: number = 0): Promise<{ notifications: any[]; total: number }> {
    const response = await this.api.get('/notifications/admin/all', {
      params: { limit, offset }
    });
    return response.data;
  }

  async getUserNotifications(limit: number = 50, offset: number = 0, unreadOnly: boolean = false): Promise<{ notifications: any[]; total: number }> {
    const response = await this.api.get('/notifications', {
      params: { limit, offset, unread_only: unreadOnly }
    });
    return response.data;
  }

  async markNotificationAsRead(notificationId: number): Promise<void> {
    await this.api.patch(`/notifications/${notificationId}/read`);
  }

  async markAllNotificationsAsRead(): Promise<void> {
    await this.api.patch('/notifications/mark-all-read');
  }

  async deleteNotification(notificationId: number): Promise<void> {
    await this.api.delete(`/notifications/${notificationId}`);
  }

  async getNotificationStats(): Promise<{ total: number; unread: number; read: number }> {
    const response = await this.api.get('/notifications/stats');
    return response.data;
  }