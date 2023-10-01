extends AudioStreamPlayer
class_name SimpleFX

func spawn() -> void:
    # Connect node to parents' parent
    var parent = get_parent()
    var parent_parent = parent.get_parent()

    var dup := duplicate() as SimpleFX
    parent_parent.call_deferred("add_child", dup)
    dup.call_deferred("play_and_remove")

func play_and_remove() -> void:
    if is_inside_tree():
        play()
        await finished
        queue_free()
