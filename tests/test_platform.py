import pathlib, subprocess, tempfile, unittest

PLATFORM = pathlib.Path(__file__).resolve().parents[1] / 'mikuui/scripts/mikuui-platform.sh'

class PlatformTests(unittest.TestCase):
    def architecture(self, machine, cpu='', dt=''):
        return subprocess.run(['/bin/sh', '-c', '. "$1";miku_arch_from "$2" "$3" "$4"', 'test', str(PLATFORM), machine, cpu, dt], capture_output=True).returncode

    def radios(self, values, mapping=False):
        with tempfile.TemporaryDirectory() as folder:
            fixture = pathlib.Path(folder) / 'nvram'
            fixture.write_text(''.join(f'{k}={v}\n' for k, v in values.items()))
            script = '. "$1";fixture="$2";miku_iface_present(){ return 0; };nvram(){ awk -F= -v key="$2" \'$1==key{print substr($0,index($0,"=")+1);exit}\' "$fixture";};miku_radios'
            if mapping:
                script += ' | miku_dual_mapping'
            return subprocess.run(['/bin/sh', '-c', script, 'test', str(PLATFORM), str(fixture)], text=True, capture_output=True)

    def test_armv8_architectures(self):
        for machine, cpu, dt in [('aarch64','',''), ('arm64','',''), ('armv8l','',''), ('armv7l','CPU architecture : 8',''), ('armv7l','CPU architecture : 7','arm,cortex-a53'), ('armv7l','','arm,cortex-a72')]:
            self.assertEqual(self.architecture(machine,cpu,dt),0,machine)

    def test_other_architectures_rejected(self):
        for machine, cpu, dt in [('x86_64','',''), ('mips','',''), ('armv7l','CPU architecture : 7','arm,cortex-a9'), ('armv7l','','')]:
            self.assertNotEqual(self.architecture(machine,cpu,dt),0)

    def test_reversed_radio_order(self):
        r=self.radios({'wl0_ifname':'eth9','wl0_nband':'1','wl1_ifname':'wl1','wl1_nband':'2'},True)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(r.stdout,'1 wl1 0 eth9\n')

    def test_tri_band_stays_read_only(self):
        values={'wl0_ifname':'eth6','wl0_nband':'2','wl1_ifname':'eth7','wl1_nband':'1','wl2_ifname':'eth8','wl2_nband':'1'}
        self.assertEqual(len(self.radios(values).stdout.splitlines()),3)
        self.assertNotEqual(self.radios(values,True).returncode,0)

    def test_six_ghz_not_treated_as_five(self):
        values={'wl0_ifname':'eth6','wl0_nband':'2','wl1_ifname':'eth7','wl1_nband':'4'}
        self.assertIn('1|eth7|4\n',self.radios(values).stdout)
        self.assertNotEqual(self.radios(values,True).returncode,0)

    def test_band_list_and_conflicts(self):
        values={'wlnband_list':'5g1<2g1<6g1','wl0_ifname':'eth6','wl1_ifname':'eth7','wl2_ifname':'eth8'}
        self.assertEqual(self.radios(values).stdout,'0|eth6|1\n1|eth7|2\n2|eth8|4\n')
        values['wl1_nband']='1'
        self.assertIn('1|eth7|0\n',self.radios(values).stdout)

    def test_invalid_interface_and_unknown_band(self):
        r=self.radios({'wl0_ifname':'../../etc/passwd','wl0_nband':'2','wl1_ifname':'eth7','wl1_nband':'99'})
        self.assertEqual(r.stdout,'1|eth7|0\n')
        self.assertNotEqual(self.radios({'wl0_ifname':'eth7','wl0_nband':'99'},True).returncode,0)

if __name__ == '__main__': unittest.main()
