extends CPUParticles2D
class_name SimpleVFX

func spawn() -> void:
    # Connect node to parents' parent
    var parent = get_parent()
    var parent_parent = parent.get_parent()

    var dup := duplicate() as SimpleVFX
    parent_parent.add_child(dup)
    dup.global_position = global_position
    dup.play_and_remove()
    # await get_tree().process_frame

func play_and_remove() -> void:
    emitting = true
    await get_tree().create_timer(lifetime).timeout
    queue_free()
