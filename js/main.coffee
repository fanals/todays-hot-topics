require.config
	baseUrl: '.'
	paths:
		# Frameworks
		domReady: 'lib/domReady'
		jquery: 'lib/jquery-1.8.0.min'
		underscore: 'lib/underscore-min'
		carousel: 'lib/jquery.liquidcarousel.pack'
		lightbox: 'lib/jquery.lightbox-0.5'
		# My files
		createCloud: 'js/createCloud'
		APIManager: 'js/APIManager'
		topStories: 'js/topStories'

# Wait for dom being ready with 'domReady!' and load jquery / underscore
require ['domReady!', 'jquery', 'underscore'], (dom) ->
	# Load carousel and lightbox AFTER jquery has been loaded because they need jquery
	require ['carousel', 'lightbox'], () ->
		# Load the files that will be needed. topStories is only needed in createCloud so it will be loaded there
		require ['createCloud', 'APIManager'], (createCloudClass, APIManager) ->

			class Main

				manager = null

				constructor: () ->
					# Elements div where to load media
					mediaElements = 
						'youtube': $('#youtube')
						'instagram': $('#instagram')
						'google': $('#google')
						'twitter': $('#twitter')

					manager = new APIManager(mediaElements)
					# Creates the cloud of topics giving the element where to load it and a callback
					new createCloudClass($('#cloud'), @cloudCreated)

				cloudCreated: () =>
					# Hide the cloud loading gif
					$("#loadingCloud").css('display', 'none')
					# When the refresh button is clicked refresh the cloud of topics
					$("#refreshButton").click =>
						new createCloudClass($('#cloud'), @cloudCreated)
					# When a topic is selected
					$("#cloud span").click ->
						# Hide the message that asks to select a topic
						$('#selectTopicMessage').css('display', 'none')
						mediaSection = $('.mediaSection')
						# Display the media sections 
						mediaSection.css('display', 'block')
						# Add a loading gif in each media section
						img = '<img class="loaders" src="img/ajax-loader.gif" />'
						$('.wrapper > ul', mediaSection).empty().append img
						selected = $('.cloudSelected')[0]
						# Remove the cloudSelected class to the old selected element
						$(selected).removeClass('cloudSelected') if selected?
						# Add the cloudSelected class to the new selected element
						$(@).addClass('cloudSelected')
						# Call the API manager passing him the topic to load for every media
						manager.load @.innerHTML

			new Main()