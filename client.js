function mouse_over(){
var agnt = navigator.userAgent.toLowerCase();
var is_ie   = ((agnt.indexOf("msie") != -1) && (agnt.indexOf("opera") == -1));
var is_nav  = ((agnt.indexOf('mozilla')!=-1) && (agnt.indexOf('spoofer')==-1)
    && (agnt.indexOf('compatible') == -1) && (agnt.indexOf('opera')==-1)
    && (agnt.indexOf('webtv')==-1) && (agnt.indexOf('hotjava')==-1));
var nvers = navigator.appVersion.substring(0,4);
var str = ''; var x,y,a;

if(is_ie){
    str=document.selection.createRange().text;
}else if(is_nav){
    str=document.getSelection();
};
if(str.length > 100 ) {	str = str.substr(0,100) };
if (str) { document.forms.search.find.value=str };
}; 

function setCookie(name, value) {
var expires="Sunday, 11-Mar-2066, 23:59:59 GMT"
var path="/"
var domain=""
var secure=""
var curCookie = name + "=" + escape(value) +
	((expires) ? "; expires=" + expires : "") +
	((path) ? "; path=" + path : "") +
	((domain) ? "; domain="+domain : "")+
	((secure) ?  "; secure" : "")
document.cookie=curCookie;
};
function refresh (){
history.go(0);
};
function logon() {
	U=document.forms['logonform'].username.value;
	P=document.forms['logonform'].password.value;
	saveit(U,P);
	refresh();
};
function logoff() {
	U="",P="";
	saveit(U,P);
};
function saveit(U,P) {
	setCookie('xg_username',U);
	setCookie('xg_password',P);
};
function newwindow(url,name) {
	open(url,name, "width=600,height=400,status=no,toolbar=no,menubar=no,scrollbars=yes");
};
