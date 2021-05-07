struct GraphQLQueries {
    static let RENDER_WIDGET = """
        query renderWidget(
            $user: UserIdInput
            $widgetType: WidgetType
            $engagementMedium: UserEngagementMedium
            $locale: RSLocale
        ) {
            renderWidget(
                user: $user
                widgetType: $widgetType
                engagementMedium: $engagementMedium
                locale: $locale
            ) {
                template
            }
        }
    """
}
