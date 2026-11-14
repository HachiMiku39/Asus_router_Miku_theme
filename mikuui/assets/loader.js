/* MIKUUI_STYLELOADER_V1: appearance only; preserve firmware page behavior. */
(function () {
  var root = document.documentElement;
  if ((' ' + root.className + ' ').indexOf(' mikuui ') < 0) root.className += ' mikuui';
  if (!document.getElementById('mikuui-style')) {
    var link = document.createElement('link');
    link.id = 'mikuui-style'; link.rel = 'stylesheet';
    link.href = '/user/mikuui/theme-2.1.0.css';
    (document.head || document.getElementsByTagName('head')[0]).appendChild(link);
  }
}());
