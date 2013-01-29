(function($){

   //
   // extends basic data types
   //

   // fp style list operate functions
   if (!$.list) $.list = function(){

     // ** func(e) return true | false
     function all(func, array){
       for (var i=0; i<array.length; i++){
	 if (!func(array[i])) return false;
       }
       return true;
     }

     // ** func(e) return true | false
     function any(func, array){
       for (var i=0; i<array.length; i++){
	 if (func(array[i])) return true;
       }
       return false;
     }

     function clone(array){
       var r = [];
       for (var i=0; i<array.length; i++){
	 r.push(array[i]);
       }
       return r;
     }

     function count(e, array){
       var c = 0;
       for (var i=0; i<array.length; i++){
	 if (e == array[i]) c++;
       }
       return c;
     }

     // ** func(e) return true | false
     function first(func, array){
       for (var i=0; i<array.length; i++){
	 if (func(array[i])) return array[i];
       }
       return undefined;
     }

     // ** func(e) return void
     function foreach(func, array){
       if(!array) return;
       for (var i=0; i<array.length; i++){
	 func(array[i]);
       }
     }

     // ** func(e, acc0) return acc1
     function foldl(func, acc0, array){
       if(!array) return acc0;
       var acc1 = acc0;
       for (var i=0; i<array.length; i++){
         acc1 = func(array[i], acc1);
       }
       return acc1;
     }

     function indexof(e, array){
       for (var i=0; i<array.length; i++){
	 if (array[i] == e) return i;
       }
       return -1;
     }

     // ** func(e) return true | false
     function last(func, array){
       for (var i=array.length - 1; i>0; i--){
	 if (func(array[i])) return array[i];
       }
       return undefined;
     }

     // ** func(e) return new element
     function map(func, array){
       var r = [];
       for (var i=0; i<array.length; i++){
	 r.push(func(array[i]));
       }
       return r;
     }

     function member(e, array){
       for (var i=0; i<array.length; i++){
	 if (array[i] == e) return true;
       }
       return false;
     }

     function remove(e, array){
       var r = [], m = false;
       for (var i=0; i<array.length; i++){
	 if (!m && array[i] == e) m = true;
	 else r.push(array[i]);
       }
       return r;
     }

     return {
       count:count, member:member, indexof:indexof, remove:remove,
       clone:clone, map:map, foreach:foreach,
       all:all, any:any, first:first, last:last
     };

   }();

   // fp style dict operate functions
   if (!$.dict) $.dict = function(){

     // ** func(k,v) return void
     function foreach(func, dict){
       for(var k in dict){
	 func(k, dict[k]);
       }
     }

     return {
       foreach:foreach
     };

   }();

   //
   // extends jquery static functions
   //

   // thread functions
   $.thread = function(f, t){
     return window.setTimeout(f, t ? t : 50);
   };
   $.cancel = function(t){
     window.clearTimeout(t);
   };

   // string functions
   $.source = function(o){
     return o.toSource();
   };
   $.unhtml = function(s){
     return s.replace('<', '&lt;').replace('>', '&gt;');
   };

   // window functions
   $.fullscreen = function(url, name){
     var opts = "channelmode=yes"; // ie need this
     opts += "scrollbars=auto,toolbar=no,location=no,directories=no,status=no,resizeable=no,copyhistory=no,menubar=no,outerWidth="+screen.availWidth+",outerHeight="+screen.availHeight+",screenX=0,screenY=0"; // ff need this
     window.open(url, name, opts).focus();
   };

   // lazy ui compositor
   /*
    * lazy ui spec ::
    * <div id="name_of_ui" class="ui">
    * </div>
    * ui exports :: using bind
    * init -> init when other ui loaded
    * show -> show when trigger
    * hide -> hide when trigger
    */
   $.lazy = (function(){

     var urls = [];
     function load(url){
       if($.list.member(url, urls)) return;
       $.ajax({
	 url:url,
	 type:'GET',
	 dataType:'html',
	 success:function(html){
	   $("body").append(html);
	   $.thread(function(){ $("body .lazy").trigger("init"); });
	   urls.push(url);
	 }
       });
     }

     // EXPORT
     return function(url){
       return {
	 load: function(){ load(url); }
       };
     };

   })();

   // box operate
   /*
    * box spec ::
    * <div id="some_id" class="box">
    * <div class="zebra"> </div>
    * <div class="title"> 登录 </div>
    * <div class="texts">
    * </div>
    * </div>
    */
   $.box = (function(){

     var last = undefined;

     function show(fn, modal){
       // add mask layer if not exist
       if($(".mask").length == 0){
	 $("body").append("<div class='mask' style='display:none;'></div>");
       }
       // center the box
       var l = ($(".mask").width() - $(fn).width()) / 2;
       var t = ($(".mask").height() - $(fn).height()) / 3;
       l = (l > 0) ? l : 0; t = (t > 0) ? t : 0;
       $(fn).css({left: l+"px", top: t+"px"});
       // fade in box as well as the mask
       if (modal === true) {
	 if (last){ $(last).fadeOut("slow"); }
	 $(fn).add(".mask").fadeIn("slow");
	 last = fn;
       } else {
	 $(fn).fadeIn("slow");
       }
     }

     function hide(fn){
       $(fn).add(".mask").fadeOut("slow");
       if (last){ last = undefined; }
     }

     // EXPORT
     return function(fn){
       return {
	 show : function(modal){ show(fn, modal); },
	 hide : function(){ hide(fn); }
       };
     };

   })();

   // form operate
   /*
    * form spec ::
    * <div id="some_id" class="form">
    * <form>
    * <div id="name_of_field">
    *   <input name="name_of_field" />
    *   <div class="hint">sometext</div>
    *   <div class="error">
    *     <span id="err_id1">err_text1</span>
    *     <span id="err_id2">err_text2</span>
    *   </div>
    * </div>
    * </form>
    * </div>
    * form #name input -> val
    * form #name .error -> err
    */
   $.form = (function(){

     function init(fn, data){
       // hints
       $("input", fn).focus(function(){
	 var n = $(this).attr("name");
	 if(n && $("#"+n+" .hint", fn).length){
           $("#"+n+" .hint", fn).show();
	 }
       }).blur(function(){
	 var n = $(this).attr("name");
	 if(n && $("#"+n+" .hint", fn).length){
	   $("#"+n+" .hint", fn).hide();
	 }
       });
       // token
       $("input[name='token']", fn).focus(function(){
	 var tmp = (new Date()).getTime();
	 $(this).next("div").before("<img src='/u/token?"+tmp+"' />");
       }).blur(function(){
	 $(this).next("img").remove();
       });
       // submit
       $("input[type='submit']", fn).click(function(){
	 $(".buttons input", fn).hide();
	 $(".buttons span", fn).show();
       });
       bind(fn, data);
     }

     function bind(fn, data){
       $(".buttons input", fn).show();
       $(".buttons span", fn).hide();
       $(".error span", fn).hide();
       if (!data) return;
       $.dict.foreach(function(k,v){
	 if (!$("#"+k, fn).length) return;
	 $.list.foreach(function(e){
	   if (!$("#"+k+" .error span#"+e, fn).length){
	     $("#"+k+" .error", fn).append("<span id='"+e+"'>"+e+"</span>");
	   }
	   $("#"+k+" .error span#"+e, fn).show();
	 }, v.err);
       }, data);
     }

     return function(fn){
       return {
	 init : function(){ init(fn); },
	 bind : function(data){ bind(fn, data); }
       };
     };

   })();

   //
   // extends jquery objects
   //

   // disable text select effect on jquery object
   $.fn.no_select = function(){
     return this.each(function(){
       if(typeof this.onselectstart != "undefined"){ //IE
	 this.onselectstart = function(){return false};
       }else if(typeof this.style.MozUserSelect != "undefined"){ //FF
	 this.style.MozUserSelect = "none";
       }else{ // Other (ie: Opera)
	 this.onmousedown = function(){return false};
       }
       this.style.cursor = "default";
     });
   };

})(jQuery);
