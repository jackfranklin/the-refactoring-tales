var tabularize = function() {
  var active = location.hash;
  if(active) {
    $(".tabs").children("div").hide();
    $(active).show();
    $(".active").removeClass("active");
    $(".tab-link").each(function() {
      if($(this).attr("href") === active) {
        $(this).parent().addClass("active");
      }
    });
  }
  $(".tabs").find(".tab-link").click(function() {
    $(".tabs").children("div").hide();
    $($(this).attr("href")).show();
    $(".active").removeClass("active");
    $(this).parent().addClass("active");
    return false;
  });
};
