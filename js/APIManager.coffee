define ['underscore', 'jquery', 'carousel', 'lightbox'], () ->

	class APIManager

		xml_to_json: 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=8&q='

		constructor: (@mediaElements) ->
			# Media configuration
			@apis = 
				'youtube':
					baseUrl: 'https://gdata.youtube.com/feeds/api/videos?'
					maxResults: 5
					createUrl: @youtubeCreateUrl
					load: @youtubeLoad
					element: @mediaElements.youtube
					title: 'Videos of '
				'instagram':
					baseUrl: 'https://api.instagram.com/v1/tags/'
					clientID:'729810e4ea4449abb6f63f99a35332f4'
					createUrl: @instagramCreateUrl
					load: @instagramLoad
					element: @mediaElements.instagram
					title: 'Pictures of '
				'google':
					baseUrl: 'http://news.google.com/news?'
					createUrl: @googleCreateUrl
					load: @googleLoad
					element: @mediaElements.google
					title: 'News of '
				'twitter':
					baseUrl: 'http://search.twitter.com/search.json?'
					createUrl: @twitterCreateUrl
					load: @twitterLoad
					element: @mediaElements.twitter
					title: 'Tweets of '

		load: (topic) ->
			# For each media call the appropriate api
			for own key, value of @apis
				value.element.prev().empty().append value.title+topic
				@apiCall value, topic

		apiCall: (api, topic) ->
			# Do the ajax call
			$.ajax api.createUrl(topic),
				type: "GET"
				dataType: "jsonp"
				cache: false
				success: api.load

		youtubeCreateUrl: (topic) => @apis.youtube.baseUrl+"q=#{topic}&max-results=#{@apis.youtube.maxResults}&orderby=published&alt=json&v=2"
		instagramCreateUrl: (topic) => @apis.instagram.baseUrl+"#{topic}/media/recent?client_id=#{@apis.instagram.clientID}"
		googleCreateUrl: (topic) => @xml_to_json+@encodeURL(@apis.google.baseUrl+"q=#{topic}&output=rss")
		twitterCreateUrl: (topic) => @apis.twitter.baseUrl+"q=#{topic}&lang=en"

		encodeURL: (url) ->
			encodedURL = ['']
			for l in url
				encodedURL.push(l.charCodeAt().toString(16))
			encodedURL.join('%')

		# When twitter answers back it creates a list of tweets <li>Tweet html</li>
		# And load the carousel
		twitterLoad: (data) =>
			content = []
			for tweet in data.results
				content.push("<li><div class='tweets'><img src='#{tweet.profile_image_url}'/><span class='tweetUserName'>#{tweet.from_user}</span><p class='tweetText'>#{tweet.text}</p></div></li>")
			$('.wrapper > ul', @apis.twitter.element).empty().append content.join('')
			@apis.twitter.element.liquidcarousel({height:200})

		# When googles answers back it creates a list of news <li>news html</li>
		# And load the carousel
		googleLoad: (data) =>
			content = []
			for news in data.responseData.feed.entries
				continue if news.content.search('font-family:arial,sans-serif"><a ') is -1
				nContent = news.content.replace('<div style="padding-top:0.8em"><img alt="" height="1" width="1"></div>', '')
				nContent = nContent.replace(/<\/font><br><font size="-1"><a.*/, '</font></div></font></td></tr></tbody></table>')
				nContent = nContent.replace(/<td valign="top"/g, '<td valign="top" class="google_news"')
				content.push("<li>#{nContent}</li>")
			$('.wrapper > ul', @apis.google.element).empty().append content.join('')
			@apis.google.element.liquidcarousel({height:130})

		# When youtube answers back it creates a list of videos <li>video html</li>
		# And load the carousel
		youtubeLoad: (data) =>
			content = []
			for video in data.feed.entry
				videoID = video.id.$t.split(':')
				videoID = videoID[videoID.length-1]
				content.push("<li><iframe type='text/html' width='640' height='390' src='http://www.youtube.com/embed/#{videoID}' frameborder='0'></iframe></li>")
			$('.wrapper > ul', @apis.youtube.element).empty().append content.join('')
			@apis.youtube.element.liquidcarousel({height:400})

		# When instagram answers back it creates a list of pictures <li>picture html</li>
		# Load the carousel and the lightbox on every pictures
		instagramLoad: (data) =>
			content = []
			for img in data.data
				imageUrl = img.images.standard_resolution.url
				content.push("<li><a href='#{imageUrl}' rel='lightbox'><img src='#{imageUrl}' alt='' /></a></li>")
			$('.wrapper > ul', @apis.instagram.element).empty().append content.join('')
			@apis.instagram.element.liquidcarousel({height:300})
			$("a[rel*='lightbox']").lightBox()
