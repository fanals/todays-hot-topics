define ['topStories', 'underscore', 'jquery'], (topStoriesClass) ->
	class createCloud
		indexesToHide: [0,3,4,5,6,7,8,10,11,12,15,16,17,18,19,20,22,23,24,35,36,46,47,48,49,50,58,59]
		numberOfTopics: 32
		cloudRowLength: 12
		pointsForAppearance: 20
		pointsForRanking: 10
		cloud: null
		classes: []

		constructor: (@cloudDiv, @cbDone) ->
			# Add a loading gif in the cloud
			@cloudDiv.empty().append('<img id="loadingCloud" src="img/ajax-loader.gif" />')
			# Get the top stories
			new topStoriesClass(@numberOfTopics, @pointsForAppearance, @pointsForRanking, @create)
			# Creates the default topic cloud object
			@cloud = ({'name': 'a', 'visible': (if i not in @indexesToHide then 1 else 0), 'points': 0} for i in [0..59])
			# Creates an object that contains a class name for all categories. If a topic gets 50 or more points it will be important1
			# Between 40 and 49 = important2 etc etc (see @display)
			i = 0
			for i in [0..90]
				if i >= 50
					@classes.push('important1')
				else if i >= 40
					@classes.push('important2')
				else if i >= 30
					@classes.push('important3')
				else if i >= 25
					@classes.push('important4')
				else
					@classes.push('important5')

		create: (topStories) =>
			# Shuffle the top stories to have a random cloud display
			topStories = _(topStories).shuffle()
			i = 0
			# Insert every top stories in the cloud object
			_(@cloud).each (el) ->
				if el.visible
					story = topStories[i++]
					el.name = story.name
					el.points = story.points
			@display()
			
		display: () ->
			HTML= ["<div class='row' style='margin-top: 15px;'>"]
			i = 1
			l = @cloud.length
			# Creates the HTML for the cloud
			for topic in @cloud
				style = "opacity: "+topic.visible+";"
				HTML.push "<div class='span1'><span class='"+@classes[topic.points]+"' style='"+style+"'>"+topic.name+"</span></div>"
				if i % @cloudRowLength is 0 and i isnt l 
					HTML.push "</div>"
					HTML.push "<div class='row' style='margin-top: 10px;'>"
				i++
			HTML.push "</div>"
			HTML.push "<button id='refreshButton' class='btn btn-primary'>Refresh</button>"
			# Append the HTML created in the cloudDiv element
			cloudElement = $(@cloudDiv).append(HTML.join(''))
			# Checks for collisions between topics
			@checkCollisions(cloudElement)

		checkCollisions: (cloudElement) ->
			# Checks if two topics overlap. If they do, selects the topic with less points and hides it
			$(cloudElement).children().each (i, row) =>
				$(row).children().each (i, div) =>
					if $(div).next().length
						first = $($(div).children()[0])
						second = $($(div).next().children()[0])
						if @collision(first, second)
							if parseInt(first.css('font-size').substr(0, 2)) >= parseInt(second.css('font-size').substr(0, 2))
								second.css('opacity', 0)
							else
								first.css('opacity', 0)
			# The cloud is now created so time to call the callback
			@cbDone()

		collision: ($div1, $div2) ->
			# Return True if $div1 and $div2 overlap
			x1 = $div1.offset().left
			y1 = $div1.offset().top
			h1 = $div1.outerHeight(true)
			w1 = $div1.outerWidth(true)
			b1 = y1 + h1
			r1 = x1 + w1
			x2 = $div2.offset().left
			y2 = $div2.offset().top
			h2 = $div2.outerHeight(true)
			w2 = $div2.outerWidth(true)
			b2 = y2 + h2
			r2 = x2 + w2  
			!(b1 < y2 || y1 > b2 || r1 < x2 || x1 > r2)
	      