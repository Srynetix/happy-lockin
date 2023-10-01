extends CPUParticles2D
class_name SimpleVFX

func spawn() -> void:
    # Connect node to parents' parent
    var parent = get_parent()
    var parent_parent = parent.get_parent()

    var dup := duplicate() as SimpleVFX
    parent_parent.call_deferred("add_child", dup)
    dup.set_deferred("global_position", global_position)
    dup.call_deferred("play_and_remove")

func play_and_remove() -> void:
    if is_inside_tree():
        emitting = true
        await get_tree().create_timer(lifetime).timeout
        queue_free()
