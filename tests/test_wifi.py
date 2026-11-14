import pathlib,subprocess,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]/'mikuui/scripts'
class WifiTests(unittest.TestCase):
 def validate(self,*args):return subprocess.run(['/bin/sh',str(ROOT/'mikuui-wifi.sh'),'validate',*args],capture_output=True).returncode
 def patch(self,text,on24=1,on5=0,p24='0:',p5='1:'):
  return subprocess.run(['awk','-v',f'on24={on24}','-v',f'on5={on5}','-v',f'prefix24={p24}','-v',f'prefix5={p5}','-v','q24=120','-v','q5=114','-f',str(ROOT/'mikuui-wifi-patch.awk')],input=text,text=True,capture_output=True)
 def test_valid_range(self):
  for n in ['5','20','24.25','28.5']:self.assertEqual(self.validate('1',n,'0','20'),0)
 def test_invalid_input(self):
  for n in ['0','4.75','28.75','40','nan','20;reboot','$(reboot)','20.12','-5','1e1','']:
   self.assertNotEqual(self.validate('1',n,'0','20'),0,n)
  self.assertNotEqual(self.validate('0','20','0','20'),0)
 def test_selected_band_only(self):
  text='territory_code=CN/01\n0:maxp2ga0=0x6E\n0:maxp2ga1=110\n1:maxp5gb0a0=0x6C\nsecret=unchanged\n'
  r=self.patch(text);self.assertEqual(r.returncode,0,r.stderr)
  self.assertEqual(r.stdout,'territory_code=CN/01\n0:maxp2ga0=0x78\n0:maxp2ga1=120\n1:maxp5gb0a0=0x6C\nsecret=unchanged\n')
 def test_arrays_and_sb_prefix(self):
  r=self.patch('sb/1/maxp5ga0=0x6A,108,0x6C\nsb/2/maxp5ga0=0x60\n',0,1,'sb/0/','sb/1/')
  self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(r.stdout,'sb/1/maxp5ga0=0x72,114,0x72\nsb/2/maxp5ga0=0x60\n')
 def test_missing_selected_band(self):self.assertNotEqual(self.patch('other=1\n').returncode,0)
 def test_unknown_format_aborts(self):
  for value in ['bad','0x6E;reboot','1,,2','']:
   self.assertNotEqual(self.patch('0:maxp2ga0='+value+'\n').returncode,0)
 def test_key_prefix_boundary(self):
  r=self.patch('10:maxp2ga0=100\n0:maxp2ga0=110\n0:maxp2g_extra=110\n',p24='0:')
  self.assertIn('10:maxp2ga0=100\n',r.stdout);self.assertEqual(r.returncode,0)
 def test_duplicate_power_keys_rejected(self):
  self.assertNotEqual(self.patch('0:maxp2ga0=110\n0:maxp2ga0=120\n').returncode,0)
 def profile_roundtrip(self,data):
  with tempfile.TemporaryDirectory() as d:
   source=pathlib.Path(d)/'profile';text=pathlib.Path(d)/'text';out=pathlib.Path(d)/'out'
   source.write_bytes(data)
   result=subprocess.run(['/bin/sh',str(ROOT/'mikuui-wifi-format.sh'),'decode',str(source),str(text)],capture_output=True)
   if result.returncode:return result.returncode,None,None
   fmt=result.stdout.decode().strip()
   encoded=subprocess.run(['/bin/sh',str(ROOT/'mikuui-wifi-format.sh'),'encode',fmt,str(text),str(out)],capture_output=True)
   self.assertEqual(encoded.returncode,0,encoded.stderr)
   self.assertEqual(out.read_bytes(),data)
   return 0,fmt,text.read_text()
 def test_nul_profile_roundtrip(self):
  data=b'boardnum=100\x000:maxp2ga0=0x6E\x001:maxp5ga0=108\x00\x00'
  code,fmt,text=self.profile_roundtrip(data)
  self.assertEqual((code,fmt),(0,'nul'))
  patched=self.patch(text)
  self.assertEqual(patched.returncode,0,patched.stderr)
  self.assertEqual(patched.stdout.replace('\n','\0').encode(),b'boardnum=100\x000:maxp2ga0=0x78\x001:maxp5ga0=108\x00\x00')
 def test_line_profile_roundtrip(self):self.assertEqual(self.profile_roundtrip(b'0:maxp2ga0=110\nother=1\n')[1],'lines')
 def test_unsafe_profile_formats(self):
  for data in [b'a=1\x00b=2\n\x00',b'a=\xff\x00\x00',b'a=1\x00b=2',b'a=1',b'']:
   self.assertNotEqual(self.profile_roundtrip(data)[0],0,data)
if __name__=='__main__':unittest.main()
