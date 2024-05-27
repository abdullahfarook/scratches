Set-Location C:\repos\OtaskiESAdminPortal
$statePath = "src/BinaryPlate.BlazorPlate.Tdap/States";
$interfacePath = "src/BinaryPlate.BlazorPlate.Tdap/Contracts/Consumers/App";
$clientPath = "src/BinaryPlate.BlazorPlate.Tdap/Consumers/HttpClients/App";
$dtoPath = "src/BinaryPlate.Shared";
$queryFilterPath = "src/BinaryPlate.BlazorPlate.Tdap/Models/QueryFilters";
# example state class
#namespace BinaryPlate.BlazorPlate.Tdap.States;
#
#public class StationListState
#(
#IStationClient stationClient,
#SnackbarApiExceptionProvider snackbarApiExceptionProvider,
#NavigationManager navigationManager,
#BreadcrumbService breadcrumbService
#) : BaseState
#{
#public MudTable<StationDto> Table;
#private readonly GetStationsQuery _getStationsQuery = new();
#private string SearchString { get; set; }
#public PagedList<StationDto> StationPaginator = new();
#
#public void SetBreadCrumbItems()
#{
#breadcrumbService.SetBreadcrumbItems(breadcrumbItems:
#[
#new BreadcrumbItem(text: Resource.Home, href: "/"),
#new BreadcrumbItem(text: "Locations", href: "manage/stations", disabled: true)
#]);
#}
#
#public async Task<TableData<StationDto>> ServerReload(TableState state)
#{
#_getStationsQuery.SearchText = SearchString;
#
#_getStationsQuery.PageNumber = state.Page;
#
#_getStationsQuery.RowsPerPage = state.PageSize;
#
#_getStationsQuery.SortBy = state.SortDirection == SortDirection.None ? string.Empty : $"{state.SortLabel} {state.SortDirection}";
#
#var response = await GetStations(_getStationsQuery);
#var tableData = new TableData<StationDto>()
#{
#Items = response.Items,
#TotalItems = response.TotalRows
#};
#return tableData;
#}
#
#public void FilterStations(string searchString)
#{
#SearchString = searchString;
#Table.ReloadServerData();
#}
#
#public void ShowDetail(Guid id)
#{
#
#navigationManager.NavigateTo($"stations/{id}");
#}
#
#public async Task<PagedList<StationDto>> GetStations(FilterableQuery filter)
#{
#return StationPaginator = await stationClient.GetPaginatedStations(filter);
#}
#}

# example interface client
#namespace BinaryPlate.BlazorPlate.Tdap.Contracts.Consumers.App;
#
#public interface IStationClient
#{
#    Task<PagedList<StationDto>> GetPaginatedStations(FilterableQuery request);
#}

# example client implementation
#namespace BinaryPlate.BlazorPlate.Tdap.Consumers.HttpClients.App;
#
#public class StationsClient(IHttpService httpService,SnackbarApiExceptionProvider snackbar) : BaseClient(httpService,snackbar), IStationClient
#{
#public async Task<PagedList<StationDto>> GetPaginatedStations(FilterableQuery request)
#{
#var query = CreatePageQuery<StationDto>(request);
#if(!string.IsNullOrEmpty(request.SearchText))
#{
#query = query.Filter((s,f)=> f.Contains(f.ToLower(s.Name),request.SearchText));
#}
#var result = await GetODataResult<ODataResult<StationDto>>(query);
#return new PagedList<StationDto>(result, request);
#}
#}

# example QueryFilter
#namespace BinaryPlate.BlazorPlate.Tdap.Models.QueryFilters;
#
#public class StationQueryFilter : FilterableQuery
#{
#
#}
# array of above entites and plural i.e  {Name=ActionHistory,Plural=ActionHistories}
$entities = @(
#    @{Name="Setting";Plural="Settings"}
#    @{Name="ChargePoint";Plural="ChargesPoints"},
#    @{Name="ServiceSession";Plural="ServiceSessions"}
)
# itrate $entities


foreach ($entity in $entities)
{
    $queryFilterName = "$($entity.Name)QueryFilter";
    $queryFilterContent = @"
namespace BinaryPlate.BlazorPlate.Tdap.Models.QueryFilters;
public class $queryFilterName : FilterableQuery
{

}
"@;
    $queryFilterContent | Set-Content -Path "$queryFilterPath/$queryFilterName.cs";
    
    
    $dtoName = "$($entity.Name)Dto";
    $interfaceName = "I$($entity.Name)Client";
    $clientName = "$($entity.Name)Client";
    
    $dtoContent = @"
namespace BinaryPlate.Shared;
public class $dtoName
{

}
"@;
    $interfaceContent = @"
namespace BinaryPlate.BlazorPlate.Tdap.Contracts.Consumers.App;
public interface $interfaceName
{
    Task<PagedList<$dtoName>> GetPaginated$($entity.Plural)(FilterableQuery request);
}
"@;
    $clientContent = @"
namespace BinaryPlate.BlazorPlate.Tdap.Consumers.HttpClients.App;
public class $clientName : BaseClient, $interfaceName
{
    public $clientName(IHttpService httpService,SnackbarApiExceptionProvider snackbar) : base(httpService,snackbar)
    {
    }
    public async Task<PagedList<$dtoName>> GetPaginated$($entity.Plural)(FilterableQuery request)
    {
        var query = CreatePageQuery<$dtoName>(request);
        if(!string.IsNullOrEmpty(request.SearchText))
        {
            query = query.Filter((s,f)=> f.Contains(f.ToLower(s.Name),request.SearchText));
        }
        var result = await GetODataResult<ODataResult<$dtoName>>(query);
        return new PagedList<$dtoName>(result, request);
    }
}
"@;
    
    $dtoContent | Set-Content -Path "$dtoPath/$dtoName.cs";
    $interfaceContent | Set-Content -Path "$interfacePath/$interfaceName.cs";
    $clientContent | Set-Content -Path "$clientPath/$clientName.cs";
    
    $stateName = "$($entity.Name)ListState";
    $stateContent = @"
using BinaryPlate.BlazorPlate.Tdap.Models.QueryFilters;
namespace BinaryPlate.BlazorPlate.Tdap.States;


public class $stateName
(
    I$($entity.Name)Client $($entity.Name.ToLower())Client,
    SnackbarApiExceptionProvider snackbarApiExceptionProvider,
    NavigationManager navigationManager,
    BreadcrumbService breadcrumbService
) : BaseState
{
    public MudTable<$($entity.Name)Dto> Table;
    private readonly $($entity.Name)QueryFilter _get$($entity.Name)QueryFilter = new();
    private string SearchString { get; set; }
    public PagedList<$($entity.Name)Dto> $($entity.Name)Paginator = new();

    public void SetBreadCrumbItems()
    {
        breadcrumbService.SetBreadcrumbItems(breadcrumbItems:
        [
            new BreadcrumbItem(text: Resource.Home, href: "/"),
            new BreadcrumbItem(text: "Locations", href: "manage/$($entity.Plural.ToLower())", disabled: true)
        ]);
    }

    public async Task<TableData<$($entity.Name)Dto>> ServerReload(TableState state)
    {
        _get$($entity.Name)QueryFilter.SearchText = SearchString;

        _get$($entity.Name)QueryFilter.PageNumber = state.Page;

        _get$($entity.Name)QueryFilter.RowsPerPage = state.PageSize;

        _get$($entity.Name)QueryFilter.SortBy = state.SortDirection == SortDirection.None ? string.Empty : $"{state.SortLabel} {state.SortDirection}";

        var response = await Get$($entity.Plural)(_get$($entity.Name)QueryFilter);
        var tableData = new TableData<$($entity.Name)Dto>()
        {
            Items = response.Items,
            TotalItems = response.TotalRows
        };
        return tableData;
    }

    public void Filter$($entity.Plural)(string searchString)
    {
        SearchString = searchString;
        Table.ReloadServerData();
    }

    public void ShowDetail(Guid id)
    {
        navigationManager.NavigateTo("$($entity.Plural.ToLower())/{id}");
    }

    public async Task<PagedList<$($entity.Name)Dto>> Get$($entity.Plural)(FilterableQuery filter)
    {
        return $($entity.Name)Paginator = await $($entity.Name.ToLower())Client.GetPaginated$($entity.Plural)(filter);
    }
}
"@;
   
#    $stateContent | Set-Content -Path $statePath;
    $stateContent | Set-Content -Path "$statePath/$stateName.cs";
}
