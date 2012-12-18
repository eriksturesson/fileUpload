Images = new Meteor.Collection("images")

if Meteor.isClient
	#fires event when a file is selected in the input filed 
	Template.file_form.events = 'change #upload': (event) ->
		console.log "fired upload"
		input = $("#upload")[0]
		console.log "input #{ input }"
		#if something is in the input element then start the upload with filepicker api
		if input?
			console.log "image file has been chosen"
			filepicker.store input, {mimetype: 'image/*'} , ((FPFile) ->
				console.log "Store successful:", JSON.stringify(FPFile)
				console.log FPFile.url
				#create thumbnail and store it at S3
				filepicker.convert FPFile, {width: 150, height: 150, fit: "max", format: 'jpg', quality: 60}, {location: "S3"}, ((onSuccess) ->
					console.log "conversion successful JSON string: #{ JSON.stringify(onSuccess)}"
					console.log "converting onSuccess.url: #{ onSuccess.url }"
					Images.insert
						created: new Date().getTime()
						image: FPFile.key
						thumb: onSuccess.key
					console.log "image: #{ FPFile.key } - thumb: #{ onSuccess.key }"
				), ((onError) ->
					console.log "convering Error: #{ onError }"
				), ((onProgress) ->
					console.log "converting progress: #{ onProgress }%"
					Session.set("uploadingPercentage", false)
					Session.set("conversionPercentage", onProgress.toString())
					if Session.get("conversionPercentage") is "100"
						Session.set("upload_complete", true)
						Session.set("conversionPercentage", false)
						Meteor.flush()
						$(".alert").delay(2000).fadeOut "slow", ->
							console.log "jquery fadeOut fired"
							Session.set("upload_complete", false)
				)
			), ((FPError) ->
				console.log FPError.toString()
			), (percentage) ->
				Session.set("uploadingPercentage", percentage.toString())
				console.log "Loading: #{ percentage }%"
				console.log percentage
				console.log percentage.toString()
	
	#IF there is a variable then show the accessed template
	Template.file_form.uploading_percentage = ->
		Session.get("uploadingPercentage")
	
	Template.file_form.uploading_complete = ->
		Session.get("upload_complete")
	
	Template.file_form.rendering_percentage = ->
		Session.get("conversionPercentage")
	
	#When the template file_form is rendered then initiate fileupload
	Template.file_form.rendered = ->
		filepicker.setKey('AMjxEmUjxTZKeGg7RZg9Zz')
		$('.fileupload').fileupload()

	#Show the images in the database uploaded to S3
	Template.imagelist.image = ->
		Images.find {}, {sort: {created: -1}}

if Meteor.isServer
	console.log "Server Started"
