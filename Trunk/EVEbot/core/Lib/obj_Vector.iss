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
