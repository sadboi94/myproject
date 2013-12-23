angular.module('controllers.budgets', [])
.controller('BudgetController',['$scope', '$rootScope', '$state', "Bucket", ($scope, $rootScope, $state, Bucket)->
  $scope.buckets = []
  #set up rules for slider
  $scope.allocatable = $rootScope.current_user.allocatable

  setMinMax = (bucket)->
    if bucket.minimum_cents?
      bucket.minimum = parseFloat(bucket.minimum_cents) / 100
    else
      bucket.minimum = 0
    if bucket.maximum_cents?
      bucket.maximum = parseFloat(bucket.maximum_cents) / 100
    else
      bucket.maximum = 0
    bucket

  $scope.user_id = $rootScope.current_user.id
  $scope.user_allocations = []

  Bucket.query(budget_id: $state.params.budget_id, (response)->
    for b, i in response
      b.user_allocation = 0
      b.allocations = [
        {bucket_id: b.id, user_id: 1, user_color: "#111", amount: i+2*380}, 
        {bucket_id: b.id, user_id: 2, user_color: "#222", amount: i+5*100}, 
        {bucket_id: b.id, user_id: 3, user_color: "#333", amount: i+8*100}]
      setMinMax(b)
      $scope.buckets.push b
  )

  $scope.prepareUserAllocations = ->
    allocations = []
    sum = 0
    for bucket in $scope.buckets
      #eventually a prob when allocations to same bucket.
      for allocation, i in bucket.allocations
        if allocation.user_id == $scope.user_id
          allocation.label = "#{bucket.name} ($#{allocation.amount})"
          sum += allocation.amount
          if allocation.amount > 0
            allocations.push allocation

    unallocated = $scope.allocatable - sum 
    allocations.push {user_id: undefined, label: "unallocated ($#{unallocated})", amount: unallocated }
    $scope.user_allocations = allocations.reverse()

  $scope.xUserAllocations = ->
    (d)->
      d.label

  $scope.yUserAllocations = ->
    (d)->
      d.amount
    
  $scope.prepareUserAllocations()

  #$scope.update_bucket = (bucket)->
    #for bucket, i in $scope.buckets
      #if bucket.id == $scope.buckets[i].id
        #$scope.buckets[i] = bucket
        #scope.$apply() unless $rootScope.$$phase
        #return false

  $rootScope.channel.bind('bucket_created', (bucket) ->
    setMinMax(bucket.bucket)
    $scope.buckets.unshift bucket.bucket
    $scope.$apply()
  )

  $rootScope.channel.bind('bucket_updated', (bucket) ->
    for i in [0...$scope.buckets.length]
      bk = $scope.buckets[i]
      if bk.id == bucket.bucket.id
        $scope.buckets[i] = bucket.bucket
        setMinMax($scope.buckets[i])
    $scope.$apply()
  )
])