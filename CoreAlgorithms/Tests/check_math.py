"""Small CPU boundary/reference checks. Run: python -B CoreAlgorithms/Tests/check_math.py"""
import sys, math, random, unittest
from pathlib import Path
CORE=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(CORE/'Baking'),str(CORE/'Raymarch'),str(CORE/'Art')]
from bake_math import safe_octaves, combined_macro_upper_bound, scalar_mips
from trace_math import trace_transmittance, trace_reference, constant_segment, periodic_cell_boundary
from art_math import curvature_masks, structural_responses, energy_limited_blend, luminance, lut_coordinates

class MathChecks(unittest.TestCase):
    def test_periodic_step_sign_and_plane(self):
        args=((20.,10.,0.),(100.,100.,100.),(4.,4.,4.))
        p,period,dimensions=args
        self.assertAlmostEqual(periodic_cell_boundary(p,(1,0,0),period,dimensions),5.)
        self.assertAlmostEqual(periodic_cell_boundary(p,(-1,0,0),period,dimensions),20.)
        self.assertGreater(periodic_cell_boundary((25,0,0),(-1,0,0),period,dimensions),0.)
        self.assertEqual(periodic_cell_boundary(p,(0,0,0),period,dimensions),1.e30)

    def test_resolvable_octaves(self):
        self.assertEqual(safe_octaves(6,16),0)
        self.assertEqual(safe_octaves(6,32),1)
        self.assertEqual(safe_octaves(6,256),4)

    def test_morphology_upper_bound(self):
        rng=random.Random(17)
        for _ in range(1000):
            a,b=rng.randrange(256),rng.randrange(256)
            bound=combined_macro_upper_bound([a],[b])[0]/255.
            runtime=min(1.,a/255.+b/255.*rng.random())
            self.assertLessEqual(runtime,bound+1.e-12)

    def test_periodic_halo_and_hierarchy(self):
        v=[0]*64;v[0]=255
        m=scalar_mips(v,(4,4,4))
        self.assertEqual(m[0][1][-1],255)  # periodic wrap donor
        for (shape,values),(nextshape,nextvalues) in zip(m,m[1:]):
            for z in range(shape[2]):
                for y in range(shape[1]):
                    for x in range(shape[0]):
                        parent=(x//2)+nextshape[0]*((y//2)+nextshape[1]*(z//2))
                        self.assertGreaterEqual(nextvalues[parent],values[x+shape[0]*(y+shape[1]*z)])
        self.assertEqual(m[-1],((1,1,1),[255]))

    def test_mean_mip(self):
        self.assertEqual(scalar_mips([0,255,0,255],(2,2,1),False,False)[-1][1],[128])

    def test_uniform_optical_integral(self):
        result,complete,_=trace_transmittance(3.,lambda _: (.2,.4,.8),73,0.)
        self.assertTrue(complete)
        for v,s in zip(result,(.2,.4,.8)):
            self.assertAlmostEqual(v,math.exp(-s*3.),places=12)

    def test_vacuum_and_nan(self):
        self.assertEqual(trace_transmittance(5.,lambda _: (0.,0.,0.))[0],(1.,1.,1.))
        result,complete,_=trace_transmittance(1.,lambda _: (float('nan'),0.,0.))
        self.assertFalse(complete);self.assertEqual(result,(0.,0.,0.))

    def test_reference_budget_and_zero_proof(self):
        result,complete,_=trace_reference(2.,lambda _: (.1,)*3,.01,2)
        self.assertFalse(complete);self.assertEqual(result,(0.,)*3)
        result,complete,steps=trace_reference(2.,lambda _: (_ for _ in ()).throw(AssertionError()),.01,2,lambda _:2.)
        self.assertTrue(complete);self.assertEqual(result,(1.,)*3);self.assertEqual(steps,1)

    def test_segment_subdivision(self):
        one=constant_segment((0.,)*3,1.,(.7,)*3,(2.,)*3,.3,2.)
        half=constant_segment((0.,)*3,1.,(.7,)*3,(2.,)*3,.3,1.)
        two=constant_segment(*half,(.7,)*3,(2.,)*3,.3,1.)
        for a,b in zip(one[0],two[0]):self.assertAlmostEqual(a,b,places=13)
        self.assertAlmostEqual(one[1],two[1],places=13)

    def test_signed_curvature(self):
        for i in range(-100,101):
            convex,concave=curvature_masks(i/100.,.8)
            self.assertEqual(convex*concave,0.)
            self.assertTrue(0<=convex<=.8 and 0<=concave<=.8)

    def test_art_responses_and_no_key_light(self):
        rng=random.Random(19)
        for _ in range(1000):
            r=structural_responses(rng.uniform(-1,1),rng.uniform(-1,1),rng.random(),*[rng.random()*10 for _ in range(4)],rng.random())
            self.assertTrue(all(math.isfinite(v) and 0<=v<=1 for v in r.values()))
            self.assertLessEqual(r['dark_edge'],.85)
        r=structural_responses(1,1,1,10,10,10,0,1,False)
        self.assertEqual([r[k] for k in ('silver','powder','inner_glow','dark_edge')],[0.,]*4)

    def test_energy_ceiling_and_black(self):
        self.assertEqual(energy_limited_blend((0.,)*3,(100.,)*3),(0.,)*3)
        rng=random.Random(23)
        for _ in range(1000):
            p=tuple(rng.random()*10 for _ in range(3));a=tuple(rng.random()*100 for _ in range(3))
            out=energy_limited_blend(p,a,.65,1.5)
            self.assertLessEqual(luminance(out),1.5*luminance(p)+1.e-10)

    def test_lut_slice_edges(self):
        for w,h,n in [(256,256,8),(1,1,8),(7,15,4)]:
            for s in [-1.,0.,.5,1.,2.]:
                uv0,uv1,t=lut_coordinates(w,h,n,.3,.8,s)
                self.assertTrue(all(0<v<=1 for v in (*uv0,*uv1)))
                self.assertTrue(0<=t<1)

if __name__=='__main__':unittest.main(verbosity=2)
