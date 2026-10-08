"""Function-level CPU adaptation of ShaftTraceSun.
Ray-shell intersection and density lookup are callbacks supplied by the caller.
The independent constant-segment scattering example uses Beer-Lambert maths;
it does not reproduce the UE cloud physical integrator.
"""
from math import exp, expm1, isfinite, floor

def periodic_cell_boundary(coordinates_cm, direction, period_cm, dimensions, mip=0, axes=3):
    """CPU mirror of TACloudDistanceToPeriodicCellBoundary; distance is in cm.
    Parallel axes do not constrain travel. A tiny positive boundary floor
    prevents a negative-direction ray on an exact grid plane from stalling.
    Uniform cells require aligned mip footprints for a conservative skip.
    """
    distance = 1.e30
    for axis in range(axes):
        period = max(period_cm[axis],1.)
        cells = max(1.,floor(dimensions[axis]/2.**mip))
        cell = (coordinates_cm[axis]/period % 1.)*cells
        rate = direction[axis]/period*cells
        if abs(rate)>1.e-8:
            fraction = cell % 1.
            remaining = max(1.e-4,1.-fraction if rate>0 else fraction)
            distance = min(distance,remaining/abs(rate))
    return distance

def trace_transmittance(end_m, density_at_m, count=64, cutoff=.001):
    """Midpoint full-path quadrature. Returns (RGB T, complete, query count).
    Density callback returns RGB extinction in 1/m. No spatial proof is implied.
    """
    if not isfinite(end_m) or end_m < 0 or count < 1:
        raise ValueError("invalid path or budget")
    if end_m == 0:
        return (1.,1.,1.), True, 0
    ds = end_m / count
    transmission = [1.,1.,1.]
    for index in range(count):
        sigma = tuple(density_at_m((index+.5)*ds))
        if len(sigma) != 3 or not all(isfinite(v) for v in sigma):
            return (0.,0.,0.), False, index+1
        transmission = [t*exp(-max(s,0.)*ds) for t,s in zip(transmission,sigma)]
        if max(transmission) < cutoff:
            return (0.,0.,0.), True, index+1
    return tuple(transmission), True, count

def trace_reference(end_m, density_at_m, fine_m, budget, empty_interval=None):
    """Bounded fine march; only a supplied conservative zero-density proof skips.
    Callback returns skip length in metres or zero. Incomplete queries return
    zero transmission, avoiding invented full visibility on budget exhaustion.
    A caller must ensure a skip stays inside its halo/upper-bound footprint.
    """
    if end_m < 0 or fine_m <= 0 or budget < 1 or not all(isfinite(v) for v in (end_m,fine_m)):
        raise ValueError("invalid reference domain")
    travel, queries = 0., 0
    transmission = [1.,1.,1.]
    while travel < end_m and queries < budget:
        skip = empty_interval(travel) if empty_interval else 0.
        if not isfinite(skip):
            break
        ds = min(skip if skip > 0 else fine_m, end_m-travel)
        if ds <= 0 or travel+ds <= travel:
            break
        if skip <= 0:
            sigma = tuple(density_at_m(travel+.5*ds))
            if len(sigma)!=3 or not all(isfinite(v) for v in sigma):
                break
            transmission = [t*exp(-max(s,0.)*ds) for t,s in zip(transmission,sigma)]
        queries += 1
        travel += ds
        if max(transmission) < .001:
            return (0.,0.,0.), True, queries
    return (tuple(transmission) if travel>=end_m else (0.,0.,0.)), travel>=end_m, queries

def constant_segment(scattering, transmission, albedo, incident, sigma_per_m, length_m):
    """Independent explanatory Beer-Lambert rewrite for a homogeneous segment.
    incident includes the desired phase/light weighting. Albedo is dimensionless.
    """
    if sigma_per_m < 0 or length_m < 0 or not isfinite(sigma_per_m*length_m):
        raise ValueError("invalid optical interval")
    opacity = -expm1(-sigma_per_m*length_m)
    return tuple(c+transmission*max(a,0.)*max(l,0.)*opacity
                 for c,a,l in zip(scattering,albedo,incident)), transmission*exp(-sigma_per_m*length_m)
