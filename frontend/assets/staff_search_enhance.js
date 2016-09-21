function SearchFacetsControl() {
	// sets the number of facets to initally display within each facet group
	this.NUMBER_OF_FACETS = 5;
	this.setupSearchFacetControlAction();
}

function SearchScopecontentControl() {
	this.setupSearchScopecontentControlAction();
}

// facet toggle controller
SearchFacetsControl.prototype.setupSearchFacetControlAction = function() {
var self = this;
	// if a facet has more than 5 entries, hide those greater than 5 and add a more/fewer toggle
	$('ul.search-facets').each(function() {
		if ($(this).children('li').length > self.NUMBER_OF_FACETS) {
			var facetType = $(this).prev('h5').text()+'s';
			var facetTemplate = AS.renderTemplate("facet_template_actions", {facetType: facetType});
			$(this).children('li:gt(' + (self.NUMBER_OF_FACETS - 1) + ')').hide();
			$(this).append(facetTemplate);
		}
	});
	$('.facet-toggle').click( function(e) {
		e.preventDefault();
		$(this).siblings('li:gt(' + (self.NUMBER_OF_FACETS - 1) + ')').toggle(400);
		$(this).children('.more-facets, .fewer-facets').toggle();
	});
}

// scope content toggle controller
SearchScopecontentControl.prototype.setupSearchScopecontentControlAction = function() {
	var more = ".scopecontent-more";
	var less = ".scopecontent-less";
	var moreControl = ".scopecontent-more-control";
	var ellipse = ".scopecontent-ellipse";
	
	$(moreControl).click(function() {
		$(this).siblings(ellipse).hide();
		$(this).siblings(more).show();
		$(this).hide();
	});
	$(more).on('click', less, function() {
		$(this).parent(more).hide();
		$(this).parent().siblings(moreControl).show();
		$(this).parent().siblings(ellipse).show();
	});
}

$(function() {
  new SearchFacetsControl();
  new SearchScopecontentControl();
});