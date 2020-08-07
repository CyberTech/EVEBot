/*

This data doesn't apply here really, but it's good enough here for now -- CyberTech

Missile range:
	http://www.eveonline.com/ingameboard.asp?a=topic&threadID=771647&page=1#9

	Current consensus of an acceleration formula for ships is

	V(t) = (1-e^(-t/(ma)))Vmax

	All missiles fly such a short time, that their velocity never really reach the maximum velocity.
	That alone proves that max flight time*maximum velocity is too optimistic formula.

	The guaranteed range of missiles is with the formula:

	s(t) = (a(-1+e^(-t/(ma)))m+t)Vmax

	where
		s(t) = function for distance traveled over time t
		t = time
		m = mass / 1,000,000
		a = inertia modifier
		Vmax = maximum velocity

	This falls short of the range that missiles really reach. Also missiles range seem to differ randomly by a few
	kilometers. So my theory was that missiles check their state only every second or so, which would mean that the
	maximum range of missiles would vary roughly by their maximum velocity. You might think this as an falloff, even
	though falloff is a curve and this missile range variation seems to be linear.

	The way I use currently to show missile range is first of all assume both shooter and target are stationary. Then
	take the guaranteed range formulas result as a base number and add the maximum velocity of the missile as variation.
	Which for a Golem firing normal torps would look like:

		Vmax=3881
		t=10.35
		a=1000
		m=1.5E-3

		Range = 34353 (+3881)

Time to warp: (From aligned)
	V(t) = Vmax*(1-e^-(t / (A*M)))

	V(t) = Velocity after time t (in seconds)
	Vmax = Max Velocity
	t = Time in seconds
	A = Inertia Modifier
	M = Total mass / 1,000,000

	Time to warp = M * A * 1.38629436111989 (or -ln(0.25)).

Distance Traveled Before Warp:
	float e = 2.71828182845904523536
	float IM = MyShip.IntertialModifier * MyShip.Mass
	float WarpTime = IM * 10^-6 * - log(1 - (MyShip.MaxVelocity*0.75) / MyShip.MaxVelocity) (this one doesn't work, use the one above)
	float Seconds = 1
	float SpeedAfterTime = MyShip.MaxVelocity * (1 - e^(-Seconds * 10^6 / IM)
	float TotalMetersTravelledEnteringWarp = ((MyShip.MaxVelocity*0.75) + MyShip.Velocity)*WarpTime/2

	D = (Vf + Vo)*t/2
	where:
	D is the unknown distance
	Vf is the final speed
	Vo is the initial speed
	t is the elapsed time

Time to warp (including align time):
	http://www.eveonline.com/ingameboard.asp?a=topic&threadID=723019, post #5

Orbital Speed/Radius:
	http://www.eveonline.com/ingameboard.asp?a=topic&threadID=498317&page=1#27
	post 27 describes the max orbital speed at radius, or the min radius at orbital speed

	Another parameter can "cap" the acceleration, and make it less than it should be. It's the (current orbit speed) / (max ship speed) ratio.

	---
		I made some tests orbiting things and calculated the effective acceleration.

		Effective acceleration : Aeff = 2 Veff sin(Vrot/2)

		With Vrot = angular rotation speed in rad/s while orbiting, and Veff = current ship orbiting speed.

		Vrot = 2Pi/T with T = period.
		T = 2 Pi R/Veff with R = radius = orbiting distance.

		So Aeff = 2 Veff sin(Veff/(2R))

		Now put on a graph X = Veff/Vmax = speed ratio, and Y = Aeff/Amax = accel ratio.

		With Amax = Vmax / I and I = inertia = A M / 10^6
		and Vmax = max straight line ship speed

		Graph obtained from some Crow tests

		Looks like a circle, eh ? Laughing

		And indeed it is. When orbiting, Aeff is limited by the following relationship :
		(Aeff/Amax)² + (Veff/Vmax)² = 1.

		So, for a given orbiting speed Veff, corresponding orbit distance R can be calculated with this formula :

		R = V / (2 Arcsin(Aeff / (2Veff)))

		With Aeff = SQRT((Vmax²-Veff²)/I²)
		and I = inertia = A M / 10^6

		It actually works.

		If you're interested, all of this is applied in a small spreadsheet I made. Enter your ship & skills characteristics, your (real) orbit distance and it'll tell you your orbit speed. Et vice-versa. Quite handy. :)

		Maybe not really user-friendly, it was originally made only for a few friends, and is not even finished. But oh well...
	---

Hit chance:

	hit chance = (1/2 ^ (tracking factor + range factor))

	tracking factor = ((transversal / (range * turret tracking)) * (turret sig res / sig rad)) ^ 2

	range factor = ( max(range - optimal range, 0) / falloff) ^ 2

	 C = 0.5^((R-O)/F)^2). from http://eve.grismar.net/wikka.php?wakka=Falloff

or

	Chance to Hit = 0.5^((((Vt/(Td*Wt))*(Wsr/Tsr))^2)+((MAX(0,Td-Wor))/Wfr)^2)
		* Vt: Traversal velocity (in m/s)
		* Td: Target distance (in meters)
		* Tsr: Target signature radius (in meters)
		* Wt: Weapon tracking (in rads/s)
		* Wsr: Weapon signature resolution (in meters)
		* Wor: Weapon optimal range (in meters)
		* Wfr: Weapon falloff range (in meters)
*/

objectdef obj_Vector2D
{
 	method CalcHeadingToPoint()
 	{
 		variable float temp1
 		variable float temp2
 		variable float result
 		/* Angle to point = Atan2[y2-y1,x2-x1] */
 		temp1:Set[${Math.Calc[${Me.Y} - ${This.DestY}]}]
 		temp2:Set[${Math.Calc[${Me.X} - ${This.DestX}]}]
 		result:Set[${Math.Calc[${Math.Atan[${temp1},${temp2}]} - 90]}]
 		result:Set[${Math.Calc[${result} + (${result} < 0) * 360]}]
 		This.RequiredHeading:Set[${result}]
 	}
 	method CalcRelativeAngle()
 	{
 		declarevariable result float local ${Math.Calc[${This.RequiredHeading} - ${Me.Heading}]}
 		while ${result} > 180
 		{
 			result:Set[${Math.Calc[${result} - 360]}]
 		}
 		while ${result} < -180
 		{
 			result:Set[${Math.Calc[${result} + 360]}]
 		}
 		This.AngleDiff:Set[${result}]
 		This.AngleDiffAbs:Set[${Math.Abs[${This.AngleDiff}]}]
 	}
 	/* Game Math Functions - From http://cmldev.net/ */
 	/* Returns the dot product of two n-D vectors. */
 	member:float DotProduct()
 	{
 		return ${Math.Calc[${Me.X} * ${This.DestX} + ${Me.Y} * ${This.DestY}]}
 	}
 	/*	Returns the perp-dot product of two 2-d vectors.
 		The value returned is the dot product of right and the vector (-y,x) perpendicular to left.
 	*/
 	member:float PerpDotProduct()
 	{
 		return ${Math.Calc[${Me.X} * ${This.DestY} - ${Me.Y} * ${This.DestX}]}
 	}
 	/* Signed angle between two 2D vectors. */
 	member:float Signed_Angle_2D()
 	{
     	return ${Math.Atan[${This.PerpDotProduct},${This.DotProduct}]}
 	}
 	/* Unsigned angle between two 2D vectors. */
 	member:float Unsigned_Angle_2D()
 	{
     	return ${Math.Abs[${This.Signed_Angle_2D}]}
  }
}


objectdef obj_Vector
{
 	member:float DotProduct(int64 X1, int64 Y1, int64 Z1, int64 X2, int64 Y2, int64 Z2)
 	{
 		return ${Math.Calc[int64 X1, int64 Y1, int64 Z1, int64 X2, int64 Y2, int64 Z2}
 	}

	member:float Length(int64 X1, int64 Y1, int64 Z1, int64 X2, int64 Y2, int64 Z2)
	{
		variable int X
		variable int Y
		variable int Z
		variable float Result

		X:Set[${Math.Calc[${X2} - ${X1}]}]
		Y:Set[${Math.Calc[${Y2} - ${Y1}]}]
		Z:Set[${Math.Calc[${Z2} - ${Z1}]}]

		Result:Set[${Math.Sqrt[${X} * ${X} + ${Y} * ${Y} + ${Z} * ${Z}]}]

		return ${Result}
	}

	;Minimum Distance from Point [PointX,PointY,PointZ] to a point on the Line from [X1,Y1,Z1] to [X2,Y2,Z2]
	member:int DistancePointLine(int64 X1, int64 Y1, int64 Z1, int64 X2, int64 Y2, int64 Z2, int64 PointX, int64 PointY, int64 PointZ)
	{
		variable float Length
		Length:Set[${This.Length[${X2}, ${Y2}, ${Z2}, ${X1}, ${Y1}, ${Z1}]

		variable float tmp

		tmp:Set[${Math.Calc[((( ${PointX} - ${X1} ) * ( ${X2} - ${X1} )) + (( ${PointY} - ${Y1} ) * ( ${Y2} - ${Y1} )) + (( ${PointZ} - ${Z1} ) * ( ${Z2} - ${Z1} ))) / ( ${Length} * ${Length} )]}]

		variable point3f Intersection

		Intersection.X:Set[${Math.Calc[${X1} + ${tmp} * (${X2} - ${X1})]}]
		Intersection.Y:Set[${Math.Calc[${Y1} + ${tmp} * (${Y2} - ${Y1})]}]
		Intersection.Z:Set[${Math.Calc[${Z1} + ${tmp} * (${Z2} - ${Z1})]}]

		if ${tmp} < 0.0 || ${tmp} > 1.0
		{
			; No intersection possible, the closest point does not fall within the line segment.
			return 0
		}
		variable float Distance

		Distance:Set[${This.Length[${PointX}, ${PointY}, ${PointZ}, ${Intersection.XYZ}]}]

		return ${Distance}
	}
}