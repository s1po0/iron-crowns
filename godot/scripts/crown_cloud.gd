class_name CrownCloud
extends Node
signal completed(ok: bool, message: String)
var request: HTTPRequest
var busy=false
func refresh() -> void:
	if busy:return
	busy=true
	if request==null:
		request=HTTPRequest.new()
		request.timeout=15
		request.body_size_limit=131072
		request.use_threads=true
		add_child(request)
		request.request_completed.connect(received)
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://campaign/service.json"))
	# Fixed public-content endpoint. Never send player saves, names or credentials.
	var url=config.url+"/rest/v1/iron_campaign_chronicles?id=eq.court-road-v1&published=eq.true&select=revision,payload&limit=1"
	var error=request.request(url,PackedStringArray(["apikey: "+config.publishable_key,"Accept: application/json"]))
	if error!=OK:
		busy=false
		completed.emit(false,"چیرۆکی ئۆفلاین بەردەستە؛ پەیوەندی سەرکەوتوو نەبوو.")
func received(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	busy=false
	if result==HTTPRequest.RESULT_SUCCESS and code==200 and body.size()<=131072:
		var rows=JSON.parse_string(body.get_string_from_utf8())
		if rows is Array and rows.size()==1 and rows[0] is Dictionary and rows[0].get("payload") is Dictionary and rows[0].get("revision")==rows[0].payload.get("revision") and CrownStory.accept(rows[0].payload):
			print("IRON_CROWN_STORY_REMOTE_PASS ",rows[0].revision)
			completed.emit(true,"چیرۆکی Supabase نوێ کرایەوە · v%d" % rows[0].revision)
			return
	completed.emit(false,"چیرۆکی ناوخۆیی پارێزرا؛ ئینتەرنێت یان داتای سێرڤەر نەگونجا.")
