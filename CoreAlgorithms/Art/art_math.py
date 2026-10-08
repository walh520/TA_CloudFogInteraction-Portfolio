"""Selected CPU mathematical mirrors of the project's continuous art layer.
CloudArt.hlsli carries the complete extracted A4-A8 color sequence.
These helpers check bounded responses and energy handling, not GPU parity.
"""
from math import exp, isfinite

def saturate(x):
    return min(max(x, 0.), 1.)

def smoothstep(lo, hi, x):
    if hi <= lo:
        raise ValueError("ordered transfer thresholds required")
    t = saturate((x-lo)/(hi-lo))
    return t*t*(3.-2.*t)

def response(strength, signal):
    return 1.-exp(-max(strength,0.)*max(signal,0.))

def curvature_masks(curvature, gradient, lo=.06, hi=.30):
    k = min(max(curvature,-1.),1.)
    lo = min(max(lo,0.),.999)
    hi = min(max(hi,lo+.001),1.)
    g = saturate(gradient)
    return smoothstep(lo,hi,max(k,0.))*g, smoothstep(lo,hi,max(-k,0.))*g

def structural_responses(ndotl, mu, gradient, tau_view, tau_edge, tau_local,
                         tau_light, cavity, has_key_light=True, storm=0.):
    """Illustrative coefficients; explicit feature masks live in HLSL.
    All optical depths are dimensionless and nonnegative.
    """
    g = saturate(gradient)
    weather = 1. + saturate(storm)*.15
    wrap = saturate((ndotl+.25)/1.25) if has_key_light else .5
    if not has_key_light:
        return dict(wrap=wrap, dark_edge=0., silver=0., powder=0., inner_glow=0.)
    silver_shape = saturate(mu)**4 * response(1.,tau_edge) * g
    powder_shape = response(1.,tau_local) * (.25+.75*saturate(-mu)) * g
    inner_shape = saturate(cavity)*exp(-max(tau_light,0.))*response(1.,tau_view)
    dark_shape = max(1.-wrap,0.)**1. * g * response(1.,tau_view)
    return dict(wrap=wrap, dark_edge=.85*response(weather,dark_shape),
                silver=response(weather,silver_shape), powder=response(weather,powder_shape),
                inner_glow=response(weather,inner_shape))

def luminance(rgb):
    return sum(c*w for c,w in zip(rgb,(.2126,.7152,.0722)))

def energy_limited_blend(physical, art, strength=.65, energy_limit=1.5):
    """Matches the final limiter/blend expression, using premultiplied RGB."""
    if not all(isfinite(c) and c >= 0 for c in (*physical,*art)):
        raise ValueError("finite nonnegative RGB required")
    ceiling = luminance(physical)*max(energy_limit,1.)
    art_l = luminance(art)
    scale = ceiling/max(art_l,1.e-4) if art_l > ceiling else 1.
    t = saturate(strength)
    return tuple(p*(1.-t)+a*scale*t for p,a in zip(physical,art))

def lut_coordinates(width,height,slices,luminance_coordinate,vertical,slice_coordinate):
    """Texel-centred stacked atlas coordinates; caller samples two slices."""
    width,height=max(width,1),max(height,1)
    slices=min(max(slices,1),max(height//2,1))
    slice_height=max(height//slices,1)
    u=(.5+saturate(luminance_coordinate)*(width-1))/width
    continuous=saturate(slice_coordinate)*(slices-1)
    slice0=min(int(continuous),slices-1)
    slice1=min(slice0+1,slices-1)
    local=.5+saturate(vertical)*(slice_height-1)
    return (u,(slice0*slice_height+local)/height), (u,(slice1*slice_height+local)/height), continuous-int(continuous)
