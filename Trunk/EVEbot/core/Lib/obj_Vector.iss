/*

This data doesn't apply here really, but it's good enough here for now -- CyberTech

Missile range:
	V(t) = (1-e^(-t/(ma)))Vmax

	where
	t = time
	m = mass / 1 000 000
	a = inertia modifier
	Vmax = maximum velocity

	Now if we do a definite integral of this with respect to the flight time of OPs missile (T between 0 and 9). We get a formula:

	V(T) = (a(-1+e^(-T/(ma)))m+T)Vmax

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
