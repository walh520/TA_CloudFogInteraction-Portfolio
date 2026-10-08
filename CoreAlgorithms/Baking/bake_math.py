"""CPU adaptation of ResolveSafeOctaves, BuildScalarMips and
BuildCombinedMacroUpperBound. The array adapter requires power-of-two axes.
Values are UNorm8 bytes; x is contiguous. No texture assets or UE API calls.
"""
from math import isfinite

def safe_octaves(requested, resolution, base_cells=8., lacunarity=2., min_voxels=4, limit=4):
    if resolution < 1 or base_cells <= 0 or lacunarity <= 1 or min_voxels < 1:
        raise ValueError("invalid sampling domain")
    if not all(isfinite(v) for v in (base_cells, lacunarity)):
        raise ValueError("finite sampling domain required")
    count, frequency = 0, 1.
    for _ in range(limit):
        if base_cells * frequency * min_voxels > resolution + 1.e-4:
            break
        count += 1
        frequency *= lacunarity
    return min(max(requested, 0), count)

def combined_macro_upper_bound(skeleton, billow):
    if len(skeleton) != len(billow):
        raise ValueError("channel sizes differ")
    return [min(255, int(a) + int(b)) for a, b in zip(skeleton, billow)]

def scalar_mips(values, shape, maximum=True, dilate=True):
    """Periodic radius-one halo at mip0; max or rounded-average reduction.
    Max+halo is for occupancy; mean mips retain ordinary filtered appearance.
    This adapter deliberately accepts only aligned power-of-two dimensions.
    """
    xsize, ysize, zsize = shape
    if any(n < 1 or n & (n-1) for n in shape):
        raise ValueError("power-of-two axes required by this array adapter")
    if len(values) != xsize*ysize*zsize or any(not 0 <= v <= 255 for v in values):
        raise ValueError("invalid UNorm8 volume")
    values = list(values)
    def at(data, size, x, y, z):
        nx, ny, nz = size
        return data[(x%nx) + nx*((y%ny) + ny*(z%nz))]
    if dilate:
        radius_z = (-1, 0, 1) if zsize > 1 else (0,)
        values = [max(at(values, shape, x+dx, y+dy, z+dz)
                      for dz in radius_z for dy in (-1,0,1) for dx in (-1,0,1))
                  for z in range(zsize) for y in range(ysize) for x in range(xsize)]
    result = [(shape, values)]
    while any(n > 1 for n in shape):
        next_shape = tuple(max(1,n//2) for n in shape)
        next_values = []
        for z in range(next_shape[2]):
            for y in range(next_shape[1]):
                for x in range(next_shape[0]):
                    donors = [at(values, shape, 2*x+dx, 2*y+dy, 2*z+dz)
                              for dz in range(2 if shape[2]>1 else 1)
                              for dy in range(2 if shape[1]>1 else 1)
                              for dx in range(2 if shape[0]>1 else 1)]
                    next_values.append(max(donors) if maximum else (sum(donors)+len(donors)//2)//len(donors))
        shape, values = next_shape, next_values
        result.append((shape, values))
    return result
