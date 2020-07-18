extends RigidBody2D

export(Curve) var MovementCurve 
export(Curve) var MovementDecayCurve 
export(int,500) var MovementSpeed:int = 100
export(float,1000) var JumpForce = 100
export(float,5.0) var TimeToReachFullSpeed = 0.5
export(float,5.0) var TimeToStop:float = 0.5
export(float,100.0) var FallMultiplier:float = 2.5
export(float,10.0) var LowJumpMultiplier:float = 2.0
export var AirControl = false
export var ShouldBolt = false	
export var BoltMovementSpeed = 100

var Ground = 2
var dir
var MovementTimer:float
var PrevDir
var DirectionHasChanged:bool
var comingFromDirectionChange:bool
var JumpBuffer:bool 
var DoubleJump:bool
var IsOnGround

func _ready():
	PrevDir = 0
	dir = Vector2.ZERO
	MovementTimer = 0
	DirectionHasChanged = false
	comingFromDirectionChange = false
	JumpBuffer = false
	DoubleJump = false

#func _process(delta):
#		pass

func _integrate_forces(state):
	IsOnGround = state.get_contact_count() > 0 and int(state.get_contact_collider_position(0).y) >= int(global_position.y)
	if Input.is_action_just_pressed("Jump"):
		#CancelInvoke()
		EnableJumpBuffer()
		yield(get_tree().create_timer(0.2),"timeout")
		DisableJumpBuffer()
	
	if IsOnGround and JumpBuffer:
		Jump()
		#CancelInvoke()
		DisableJumpBuffer()
		DoubleJump = false
	
	if not IsOnGround and JumpBuffer and not DoubleJump:
		Jump()
		#CancelInvoke()
		DisableJumpBuffer()
		DoubleJump = true


func _physics_process(delta):
	var MoveDirection = get_move_direction()
	var CurveValue = 0
	
	$MovementTimer.text = "Movement Timer:"+ str(MovementTimer)
	$"Move DIrection".text = "Move Direction:" + str(MoveDirection)
	$"Direction Change".text = "Direction Changed:" + str(DirectionHasChanged)
	$Dir.text = "Dir:"+str(dir)
	$PrevDir.text = "PrevDir:" + str(PrevDir)
	
	if MoveDirection.x != 0:
		if MoveDirection.x*(-1) == PrevDir:
			DirectionHasChanged = true
#			print("DIrection changed")
		
		PrevDir = MoveDirection.x
		
		if DirectionHasChanged:
			MovementTimer -= delta
			MovementTimer = clamp(MovementTimer,0,TimeToStop)
			CurveValue = MovementDecayCurve.interpolate(MovementTimer/TimeToStop)
			$DecayValue.text = "Decay Value:" + str(CurveValue)
			
			dir = Vector2(CurveValue*sign(linear_velocity.x),MoveDirection.y) if linear_velocity.x != 0 else Vector2(0,MoveDirection.y)
			$Dir.text = "Dir when direction changed:"+str(dir)
			
			if MovementTimer == 0:
				DirectionHasChanged = false
				comingFromDirectionChange = true
				$"Label".text = "comingFromDirectionChange: true"
				MovementTimer += delta
		
		else:
			if ShouldBolt and comingFromDirectionChange:
				MovementTimer+= delta*BoltMovementSpeed
				$Bolt.text = "Bolting" + str(MovementTimer)
			else:
				MovementTimer += delta
				$Bolt.text = "Not Bolting"
			
			MovementTimer =  clamp(MovementTimer,0,TimeToReachFullSpeed)
			CurveValue = MovementCurve.interpolate(MovementTimer/TimeToReachFullSpeed)
			$CurveValue.text = "Movement Curve Value:" + str(CurveValue)
			dir = Vector2(CurveValue * MoveDirection.x, MoveDirection.y)
			$Dir.text = "Dir:"+str(dir)
	
	else:
		MovementTimer-= delta
		MovementTimer =  clamp(MovementTimer,0,TimeToStop)
		CurveValue = MovementDecayCurve.interpolate(MovementTimer/TimeToStop)
		$DecayValue.text = "Decay Value:" + str(CurveValue)
		
		if linear_velocity.length_squared() < 0.1:
			comingFromDirectionChange = false
			$"Label".text = "comingFromDirectionChange: false"
			DirectionHasChanged =  false
			PrevDir = 0
		dir = Vector2(CurveValue*sign(linear_velocity.x),MoveDirection.y) if linear_velocity.x != 0 else MoveDirection
		$Dir.text = "Dir:"+str(dir)
	
	if linear_velocity.y < 0:
		linear_velocity += Vector2.UP * gravity_scale * (FallMultiplier - 1 ) * delta
	elif linear_velocity.y > 0:
		linear_velocity += Vector2.UP * gravity_scale * (LowJumpMultiplier - 1 ) * delta
	
	if not AirControl and not IsOnGround:
		pass
	else:
		Walk(dir)

func  Walk(direction):
	linear_velocity.x = direction.x * MovementSpeed
	$Walk.text = "Walk" + str(linear_velocity)

func Jump():
	linear_velocity.y = 0
	linear_velocity += Vector2.UP * JumpForce

func EnableJumpBuffer():
	JumpBuffer = true

func DisableJumpBuffer():
	JumpBuffer = false

func get_move_direction():
	return Vector2(Input.get_action_strength("Right") - Input.get_action_strength("Left"),
				   Input.get_action_strength("Jump") - Input.get_action_strength("Down"))

