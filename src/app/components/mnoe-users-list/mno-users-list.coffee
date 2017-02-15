#
# Mnoe Users List
#
@App.directive('mnoeUsersList', ($filter, $log, $translate, MnoeUsers) ->
  restrict: 'E'
  scope: {
  }
  templateUrl: 'app/components/mnoe-users-list/mno-users-list.html'
  link: (scope, elem, attrs) ->

    # Widget state
    scope.state = attrs.view

    # Variables initialization
    scope.users =
      search: ''
      nbItems: 10
      page: 1
      pageChangedCb: (nbItems, page) ->
        scope.users.nbItems = nbItems
        scope.users.page = page
        offset = (page  - 1) * nbItems
        fetchUsers(nbItems, offset)

    # Fetch users
    fetchUsers = (limit, offset, sort = 'surname') ->
      scope.users.loading = true
      return MnoeUsers.list(limit, offset, sort).then(
        (response) ->
          scope.users.totalItems = response.headers('x-total-count')
          scope.users.list = response.data
      ).finally(-> scope.users.loading = false)

    scope.switchState = () ->
      scope.state = attrs.view = if attrs.view == 'all' then 'last' else 'all'
      displayCurrentState()

    # if view="all" is set on the directive, all the users are displayed
    # if view="last" is set on the directive, the last 10 users are displayed
    displayCurrentState = () ->
      if attrs.view == 'all'
        setAllUsersList()
        fetchUsers(scope.users.nbItems, 0)
      else if attrs.view == 'last'
        setLastUsersList()
        fetchUsers(10, 0, 'created_at.desc')
      else
        $log.error('Value of attribute view can only be "all" or "last"')

    # Display all the users
    setAllUsersList = () ->
      scope.users.widgetTitle = 'mnoe_admin_panel.dashboard.user.widget.all_users.title'
      scope.users.switchLinkTitle = 'mnoe_admin_panel.dashboard.user.widget.all_users.switch_link_title'

    # Display only the last 10 users
    setLastUsersList = () ->
      scope.users.widgetTitle = 'mnoe_admin_panel.dashboard.user.widget.last_users.title'
      scope.users.switchLinkTitle = 'mnoe_admin_panel.dashboard.user.widget.last_users.switch_link_title'

    scope.searchChange = () ->
      # Only search if the string is >= than 3 characters
      if scope.users.search.length >= 3
        scope.searchMode = true
        setSearchUsersList(scope.users.search)
      # No search string, so display current state
      else if scope.searchMode
        scope.searchMode = false
        displayCurrentState()

    # Display only the search results
    setSearchUsersList = (search) ->
      scope.users.loading = true
      scope.users.widgetTitle = 'mnoe_admin_panel.dashboard.user.widget.search_users.title'
      delete scope.users.switchLinkTitle
      search = scope.users.search.toLowerCase()
      terms = {'surname.like': "#{search}%", 'name.like': "#{search}%", 'email.like': "%#{search}%" }
      MnoeUsers.search(terms).then(
        (response) ->
          scope.users.totalItems = response.headers('x-total-count')
          scope.users.list = $filter('orderBy')(response.data, 'email')
      ).finally(-> scope.users.loading = false)

    # Initial call
    displayCurrentState()
)
