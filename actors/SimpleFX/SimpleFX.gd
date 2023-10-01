extends AudioStreamPlayer
class_name SimpleFX

func spawn() -> void:
    # Connect node to parents' parent
    var parent = get_parent()
    var parent_parent = parent.get_parent()

    var dup := duplicate() as SimpleFX
    parent_parent.add_child(dup)
    dup.play_and_remove()
    # await get_tree().process_frame

func play_and_remove() -> void:
    play()
    await finished
    queue_free()
