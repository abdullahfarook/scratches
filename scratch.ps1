Set-Location C:\repos\OtaskiESAdminPortal
$controllerPath = "src/BinaryPlate.Endpoints/Controllers/App";
$handlerPath = "src/BinaryPlate.Application/Features/App";
$corePath = "src/BinaryPlate.Core";
$dtoPath = "src/BinaryPlate.Shared";
# example controller

#[Route(template: "api/[controller]")]
#public class ChargePointsController : BaseODataController
#{
#[HttpGet]
#public async Task<IActionResult > Get(ODataQueryOptions<ChargePoint> query)
#{
#var data = await Sender.Send(request: new GetChargePoints());
#return Ok(data.ToPageResult(query));
#}
#
#[HttpGet(template: "list")]
#public async Task<IActionResult > GetList(ODataQueryOptions<ChargePointListDto> query)
#{
#var data = await Sender.Send(request: new GetChargePointList());
#return Ok(data.ToPageResult(query));
#}
#
#[HttpGet(template: "select")]
#public async Task<IActionResult > GetSelect(ODataQueryOptions<ChargePointSelectDto> query)
#{
#var data = await Sender.Send(request: new GetChargePointSelect());
#return Ok(data.ToPageResult(query));
#}
#
#[HttpGet(template: "{id}")]
#public async Task<IActionResult > Get(Guid id)
#{
#var data = await Sender.Send(request: new GetChargePointDetail(id));
#return Ok(data);
#}
#}

# example query handler
#using BinaryPlate.Shared.ChargePoints;
#namespace BinaryPlate.Application.Features.App.ChargePoints;
#
#public record GetChargePoints : IRequest<IQueryable<ChargePoint>>;
#public record GetChargePointList : IRequest<IQueryable<ChargePointListDto>>;
#public record GetChargePointSelect : IRequest<IQueryable<ChargePointSelectDto>>;
#public record GetChargePointDetail(Guid Id) : IRequest<ChargePointDetailDto>;
#
#public class ChargePointQueryHandler :
#IRequestHandler<GetChargePoints, IQueryable<ChargePoint>>,
#IRequestHandler<GetChargePointList, IQueryable<ChargePointListDto>>,
#IRequestHandler<GetChargePointSelect, IQueryable<ChargePointSelectDto>>,
#IRequestHandler<GetChargePointDetail, ChargePointDetailDto>
#{
#private readonly IApplicationDbContext _context;
#
#public ChargePointQueryHandler(IApplicationDbContext context)
#{
#_context = context;
#}
#
#public Task<IQueryable<ChargePoint>> Handle(GetChargePoints request, CancellationToken cancellationToken)
#{
#return Task.FromResult<IQueryable<ChargePoint>>(_context.ChargePoints);
#}
#
#public Task<IQueryable<ChargePointListDto>> Handle(GetChargePointList request, CancellationToken cancellationToken)
#{
#var query =
#from cp in _context.ChargePoints
#let setting = (from setting in _context.Settings
#join station in _context.Stations on setting.StationId equals station.Id
#join cb in _context.ChargeBoxes on station.Id equals cb.StationId
#where cb.Id == cp.ChargingBoxId
#select setting).FirstOrDefault()
#select new ChargePointListDto
#{
#Id = cp.Id,
#Name = cp.Name,
#ChargerCode = cp.ChargerCode,
#State = cp.State,
#UptimeYesterday = cp.UptimeYesterday,
#OccupancyYesterday = cp.OccupancyYesterday,
#SettingId = setting.Id,
#SettingName = setting.Name
#};
#return Task.FromResult(query);
#}
#
#public Task<IQueryable<ChargePointSelectDto>> Handle(GetChargePointSelect request, CancellationToken cancellationToken)
#{
#var query =
#from cp in _context.ChargePoints
#select new ChargePointSelectDto
#{
#Id = cp.Id,
#Name = cp.Name
#};
#return Task.FromResult(query);
#}
#
#public Task<ChargePointDetailDto> Handle(GetChargePointDetail request, CancellationToken cancellationToken)
#{
#throw new NotImplementedException();
#}
#}
$entities = @(
    @{Name="Setting";Plural="Settings"}
    @{Name="ActionHistory";Plural="ActionHistories"}
    @{Name="ChargeBox";Plural="ChargeBoxes"},
    @{Name="ChargePoint";Plural="ChargePoints"},
    @{Name="ConnectorType";Plural="ConnectorTypes"},
    @{Name="Customer";Plural="Customers"},
    @{Name="CustomerChargePoint";Plural="CustomerChargePoints"},
    @{Name="CustomerPaymentMethod";Plural="CustomerPaymentMethods"},
    @{Name="CustomerType";Plural="CustomerTypes"},
    @{Name="DashboardPreference";Plural="DashboardPreferences"},
    @{Name="FileHistory";Plural="FileHistories"},
    @{Name="Installer";Plural="Installers"},
    @{Name="Invoice";Plural="Invoices"},
    @{Name="Operator";Plural="Operators"},
    @{Name="Order";Plural="Orders"},
    @{Name="OrderLineItem";Plural="OrderLineItems"},
    @{Name="PaymentCard";Plural="PaymentCards"},
    @{Name="PaymentMethod";Plural="PaymentMethods"},
    @{Name="ServiceSession";Plural="ServiceSessions"},
    @{Name="Station";Plural="Stations"},
    @{Name="Transaction";Plural="Transactions"}
)
# itrate $entities and generate dtos, controller, query handler and command handler and folder in core path



# create dtos function
function createDtos($entity)
{
    $listDtoName = "$($entity.Name)ListDto";
    $selectDtoName = "$($entity.Name)SelectDto";
    $detailDtoName = "$($entity.Name)DetailDto";
    $path = "$($dtoPath)/$($entity.Plural)";
    $listDtoPath = "$($dtoPath)/$($entity.Plural)/$($listDtoName).cs";
    $selectDtoPath = "$($dtoPath)/$($entity.Plural)/$($selectDtoName).cs";
    $detailDtoPath = "$($dtoPath)/$($entity.Plural)/$($detailDtoName).cs";
    $listDtoContent = @"
namespace BinaryPlate.Shared.$($entity.Plural);
public class $listDtoName`: EntityDto
{
    public string Name { get; set; }
}
"@;
    $selectDtoContent = @"
namespace BinaryPlate.Shared.$($entity.Plural);
public class $selectDtoName`: EntityDto
{
    public string Name { get; set; }
}
"@;
    $detailDtoContent = @"
namespace BinaryPlate.Shared.$($entity.Plural);
public class $detailDtoName`: EntityDto
{
    public string Name { get; set; }
}
"@;
    if (-not (Test-Path -Path $path))
    {
        New-Item -Path $path -ItemType Directory;
    }
    $listDtoContent | Set-Content -Path $listDtoPath;
    $selectDtoContent | Set-Content -Path $selectDtoPath;
    $detailDtoContent | Set-Content -Path $detailDtoPath;
}

# create controller function
function createController($entity)
{
    $controllerName = "$($entity.Plural)Controller";
    $controllerFilePath = "$($controllerPath)/$($controllerFileName)";
    $controllerFile = "$($controllerPath)/$($controllerName).cs";
    $controllerContent = @"
using BinaryPlate.Application.Features.App.$($entity.Plural);
using BinaryPlate.Shared.$($entity.Plural);
namespace BinaryPlate.Endpoints.Controllers.App;

[Route(template: "api/[controller]")]
public class $($controllerName) : BaseODataController
{
    [HttpGet]
    public async Task<IActionResult > Get(ODataQueryOptions<$($entity.Name)> query)
    {
        var data = await Sender.Send(request: new Get$($entity.Plural)());
        return Ok(data.ToPageResult(query));
    }
    
    [HttpGet(template: "list")]
    public async Task<IActionResult > GetList(ODataQueryOptions<$($entity.Name)ListDto> query)
    {
        var data = await Sender.Send(request: new Get$($entity.Name)List());
        return Ok(data.ToPageResult(query));
    }
    
    [HttpGet(template: "select")]
    public async Task<IActionResult > GetSelect(ODataQueryOptions<$($entity.Name)SelectDto> query)
    {
        var data = await Sender.Send(request: new Get$($entity.Name)Select());
        return Ok(data.ToPageResult(query));
    }
}   
"@;
    if (-not (Test-Path -Path $controllerPath))
    {
        New-Item -Path $controllerPath -ItemType Directory;
    }
    $controllerContent | Set-Content -Path $controllerFile;
}

# create query handler function
function createQueryHandler($entity)
{
    $queryHandlerName = "$($entity.Name)QueryHandler";
    $queryHandlerFileName = "$($queryHandlerName).cs";
    $queryHandlerFilePath = "$($handlerPath)/$($entity.Plural)/$($queryHandlerFileName)";
    $queryHandlerContent = @"
using BinaryPlate.Shared.$($entity.Plural);
namespace BinaryPlate.Application.Features.App.$($entity.Plural);

public record Get$($entity.Plural) : IRequest<IQueryable<$($entity.Name)>>;
public record Get$($entity.Name)List : IRequest<IQueryable<$($entity.Name)ListDto>>;
public record Get$($entity.Name)Select : IRequest<IQueryable<$($entity.Name)SelectDto>>;
public record Get$($entity.Name)Detail(Guid Id) : IRequest<$($entity.Name)DetailDto>;

public class $($queryHandlerName): IRequestHandler<Get$($entity.Plural),IQueryable<$($entity.Name)>>,
IRequestHandler<Get$($entity.Name)List,IQueryable<$($entity.Name)ListDto>>,
IRequestHandler<Get$($entity.Name)Select,IQueryable<$($entity.Name)SelectDto>>,
IRequestHandler<Get$($entity.Name)Detail,$($entity.Name)DetailDto>
{
    private readonly IApplicationDbContext _context;
    public $($queryHandlerName)(IApplicationDbContext context)
    {
        _context = context;
    }
    public Task<IQueryable<$($entity.Name)>> Handle(Get$($entity.Plural) request, CancellationToken cancellationToken)
    {
        return Task.FromResult<IQueryable<$($entity.Name)>>(_context.$($entity.Plural));
    }
    public Task<IQueryable<$($entity.Name)ListDto>> Handle(Get$($entity.Name)List request, CancellationToken cancellationToken)
    {
        var query =
        from entity in _context.$($entity.Plural)
        select new $($entity.Name)ListDto
        {
            Id = entity.Id,
        };
        return Task.FromResult(query);
    }
    public Task<IQueryable<$($entity.Name)SelectDto>> Handle(Get$($entity.Name)Select request, CancellationToken cancellationToken)
    {
        var query =
        from entity in _context.$($entity.Plural)
        select new $($entity.Name)SelectDto
        {
            Id = entity.Id
        };
        return Task.FromResult(query);
    }
    public Task<$($entity.Name)DetailDto> Handle(Get$($entity.Name)Detail request, CancellationToken cancellationToken)
    {
        var query =
        from entity in _context.$($entity.Plural)
        where entity.Id == request.Id
        select new $($entity.Name)DetailDto
        {
            Id = entity.Id
        };
        return Task.FromResult(query.FirstOrDefault());
    }
}
"@;
    if (-not (Test-Path -Path "$($handlerPath)/$($entity.Plural)"))
    {
        New-Item -Path "$($handlerPath)/$($entity.Plural)" -ItemType Directory;
    }
    $queryHandlerContent | Set-Content -Path $queryHandlerFilePath;
}

# create command handler function
function createCommandHandler($entity)
{
    $commandHandlerName = "$($entity.Name)CommandHandler";
    $commandHandlerFileName = "$($commandHandlerName).cs";
    $commandHandlerFilePath = "$($handlerPath)/$($entity.Plural)/$($commandHandlerFileName)";
    $commandHandlerContent = @"
namespace BinaryPlate.Application.Features.App.$($entity.Plural);

public class $($commandHandlerName)
{
    private readonly IApplicationDbContext _context;
    public $($commandHandlerName)(IApplicationDbContext context)
    {
        _context = context;
    }
}
"@;
    if (-not (Test-Path -Path "$($handlerPath)/$($entity.Plural)"))
    {
        New-Item -Path "$($handlerPath)/$($entity.Plural)" -ItemType Directory;
    }
    $commandHandlerContent | Set-Content -Path $commandHandlerFilePath;
}

# create core folder function
function createCoreFolder($entity)
{
    $coreFolder = "$($corePath)/$($entity.Plural)";
    if (-not (Test-Path -Path $coreFolder))
    {
        New-Item -Path $coreFolder -ItemType Directory;
    }
}

foreach ($entity in $entities)
{
    createDtos($entity);
    createController($entity);
    createQueryHandler($entity);
    createCommandHandler($entity);
    createCoreFolder($entity);
}