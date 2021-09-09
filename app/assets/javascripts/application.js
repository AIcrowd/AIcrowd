// ---------------------- Gems ----------------------- //
//= require jquery
// require jquery_ujs
//= require rails-ujs
//= require jquery-ui
//= require jquery.remotipart
//= require popper
//= require bootstrap
//= require cocoon
//= require isInViewport
//= require turbolinks
//= require jquery.atwho
//= require social-share-button
//= require codemirror
//= require activestorage
//= require rails.validations
//= require local-time
//= require lodash
//= require select2
//= require ckeditor/plugins/codesnippet/lib/highlight/highlight.pack.js
//= require ace-rails-ap
//= require commontator/application

// --------------------- Vendor ------------------------ //
//= require jQuery-File-Upload
//= require remodal

// ------------------ Vendor / Notebooks --------------- //
// require ansi_up.min
// require es5-shim.min
// require marked.min
// require notebook.min
//= require prism.min

// ---------------------- Modules ---------------------- //
//= require modules/site
//= require modules/subnav_tabs
//= require modules/inline_validations
//= require modules/rangy_inputs
//= require modules/flash_messages
//= require modules/direct_s3_upload
//= require modules/mentions
//= require modules/modals
//= require modules/social_share
//= require modules/challenges
//= require clipboard

// ---------------------- Others --------------------- //
//= require ahoy

// ------------------------ STARTUP -------------------------- //

// Remove default Turbolinks loader
Turbolinks.ProgressBar.prototype.refresh = function () {};

Turbolinks.ProgressBar.defaultCSS = "";
let loaderTimer;

document.addEventListener("turbolinks:load", function () {
    clearTimeout(loaderTimer);
    $("[data-remodal-id=modal]").remodal();
    $("#page-content").show();
    $("#loader-container").hide();

    $(".cookies-set-jobs").click(function () {
        let date = new Date();
        let days = 14
        date.setTime(+date + (days * 86400000))
        document.cookie = "hiring_banner_closed=true; expires=" + date.toGMTString() + "; path=/";
    });

    $(".cookies-set-accept").click(function () {
        document.cookie =
            "_cookie_eu_consented=true; expires=Fri, 31 Dec 9999 23:58:59 GMT; path=/";
    });

    window.setTimeout(function () {
        $(".alert:not('.alert-cookie, .alert-fixed')").alert("close");
    }, 5000);
});

document.addEventListener("turbolinks:click", function () {
    loaderTimer = setTimeout(function () {
        $("#page-content").hide();
        $("#loader-container").show();
    }, 250);
});

$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip();
    $('[data-toggle="popover"]').popover();
    hljs.initHighlightingOnLoad();
    $('form').removeAttr('novalidate');
});

$(document).ready(function(){
    $('.clipboard-btn').tooltip({
      trigger: 'click',
      placement: 'bottom'
    });

    function setTooltip(btn, message) {
      $(btn).tooltip('show')
        .attr('data-original-title', message)
        .tooltip('show');
    }

    function hideTooltip(btn) {
      setTimeout(function() {
        $(btn).tooltip('hide');
      }, 1000);
    }

    var clipboard = new Clipboard('.clipboard-btn');

    clipboard.on('success', function(e) {
        setTooltip(e.trigger, 'Copied!');
        hideTooltip(e.trigger);
    });

});

function hidegrowl(){
    $('.growl').hide()
};

window.hideBadgesModal = function() {
    $('#badges-modal').modal('hide');
}

setInterval(hidegrowl, 15000);
