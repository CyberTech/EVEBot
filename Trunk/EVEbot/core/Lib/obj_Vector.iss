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
*/

objectdef obj_Vector
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
