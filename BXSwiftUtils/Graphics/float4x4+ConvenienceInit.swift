//**********************************************************************************************************************
//
//  float4x4+FMExtensions.swift
//	Adds convenience methods to float4x4
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import simd


//----------------------------------------------------------------------------------------------------------------------


public extension float4x4
{

	/// Returns the identity matrix.
	
	static var identity: float4x4
	{
		return float4x4(1.0,1.0,1.0,1.0)
	}

	
//----------------------------------------------------------------------------------------------------------------------


	/// Convenience initializer that adds columns: argument label for consistency with init(rows:).
	
	init( columns: [float4])
	{
		self.init(columns)
	}
	
	/// Returns a matrix with the diagonal components.
	
	init(_ a:Float,_ b:Float,_ c:Float,_ d:Float)
	{
		self.init(diagonal:float4(a,b,c,d))
	}

	
//----------------------------------------------------------------------------------------------------------------------


	/// Returns a translation matrix

	init( dx: Float=0.0, dy: Float=0.0, dz: Float=0.0 )
	{
		self.init(rows:
		[
			float4(1.0,0.0,0.0,dx ),
			float4(0.0,1.0,0.0,dy ),
			float4(0.0,0.0,1.0,dz ),
			float4(0.0,0.0,0.0,1.0)
		])
	}

	/// Returns a translation matrix

	init( dx: Double=0.0, dy: Double=0.0, dz: Double=0.0 )
	{
		self.init(dx:Float(dx),dy:Float(dy),dz:Float(dz))
	}


//----------------------------------------------------------------------------------------------------------------------


	/// Returns a zoom matrix
	
	init( zoomx: Float, zoomy: Float )
	{
		self.init(rows:
		[
			float4(zoomx,0.0,0.0,0.0),
			float4(0.0,zoomy,0.0,0.0),
			float4(0.0,0.0,1.0,0.0),
			float4(0.0,0.0,0.0,1.0)
		])
	}


	/// Returns a zoom matrix
	
	init( zoom: Float )
	{
		self.init(rows:
		[
			float4(zoom,0.0,0.0,0.0),
			float4(0.0,zoom,0.0,0.0),
			float4(0.0,0.0,1.0,0.0),
			float4(0.0,0.0,0.0,1.0)
		])
	}


	/// Returns a zoom matrix
	
	init( zoomx: Double, zoomy: Double )
	{
		self.init(zoomx:Float(zoomx),zoomy:Float(zoomy))
	}


	/// Returns a zoom matrix
	
	init( zoom: Double )
	{
		self.init(zoom:Float(zoom))
	}


	/// Returns a matrix for flipping horizontally or vertically
	
	init( flipHorizontally: Bool=false, flipVertically: Bool=false )
	{
		let h:Float = flipHorizontally ? -1.0 : 1.0
		let v:Float = flipVertically ? -1.0 : 1.0
		self.init(zoomx:h,zoomy:v)
	}


//----------------------------------------------------------------------------------------------------------------------

	
	/// Returns a rotation matrix.
	/// - parameter rotation: The rotation angle in degrees
	/// - parameter axis: The axis around which the rotation occurs
	
	init( rotation: Double=0.0, axis: double3=double3(0.0,0.0,1.0) )
	{
		let radians = rotation / 180.0 * Double.pi
		let c = cos(radians)
		let s = sin(radians)
		let c_1 = 1.0 - c
		let u = normalize(axis)
		
		self.init(columns:
		[
			float4(
				Float(c + u.x*u.x*c_1),
				Float(u.y*u.x*c_1 + u.z*s),
				Float(u.z*u.x*c_1 - u.y*s),
				0.0),
			
			float4(
				Float(u.x*u.y*c_1 - u.z*s),
				Float(c + u.y*u.y*c_1),
				Float(u.z*u.y*c_1 + u.x*s),
				0.0),
			
			float4(
				Float(u.x*u.z*c_1 + u.y*s),
				Float(u.y*u.z*c_1 - u.x*s),
				Float(c + u.z*u.z*c_1),
				0.0),
			
			float4(
				0.0,
				0.0,
				0.0,
				1.0)
		])
	}


	/// Returns a rotation matrix.
	/// - parameter rotation: The rotation angle in degrees
	/// - parameter axis: The axis around which the rotation occurs
	
	init( rotation: Float=0.0, axis: float3=float3(0.0,0.0,1.0) )
	{
		self.init(rotation:Double(rotation),axis:double3(Double(axis.x),Double(axis.y),Double(axis.z)))
	}


//----------------------------------------------------------------------------------------------------------------------


}

