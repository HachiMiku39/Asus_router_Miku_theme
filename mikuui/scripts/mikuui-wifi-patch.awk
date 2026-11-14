# Modify only selected maxp calibration fields; reject unfamiliar value formats.
function validvalue(v, a,n,i) {
 n=split(v,a,","); if(n<1)return 0;
 for(i=1;i<=n;i++) if(a[i]!~/^0[xX][0-9a-fA-F]+$/ && a[i]!~/^[0-9]+$/)return 0;
 return 1;
}
function replacevalue(v,q, a,n,i,r) {
 n=split(v,a,",");r="";
 for(i=1;i<=n;i++)r=r (i>1?",":"") (a[i]~/^0[xX]/?sprintf("0x%02X",q):sprintf("%d",q));
 return r;
}
{
 equal=index($0,"=");if(!equal){print;next}
 key=substr($0,1,equal-1);value=substr($0,equal+1);
 choose24=on24==1 && index(key,prefix24)==1 && substr(key,length(prefix24)+1)~/^maxp2g[a-zA-Z0-9_]*$/;
 choose5=on5==1 && index(key,prefix5)==1 && substr(key,length(prefix5)+1)~/^maxp5g[a-zA-Z0-9_]*$/;
 if(choose24 || choose5){
  if(!validvalue(value)){bad=1;print "Unsupported calibration value: " key > "/dev/stderr";next}
  if(choose24)count24++;else count5++;
  print key "=" replacevalue(value,choose24?q24:q5);
 } else print;
}
END {
 if(bad || (on24==1 && !count24) || (on5==1 && !count5))exit 2;
}
