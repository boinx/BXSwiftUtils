//**********************************************************************************************************************
//
//  MatrixOperators.swift
//	Adds convenience operators to matrix_float4x4
//  Copyright ©2017 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import simd


//----------------------------------------------------------------------------------------------------------------------


extension matrix_float4x4
{
	/// Performs a matrix multiplication of type C = A * B
	
	public static func *( A: matrix_float4x4, B: matrix_float4x4 ) -> matrix_float4x4
	{
		return matrix_multiply(A,B)
	}

	/// Performs a matrix multiplication of type A *= B
	
	public static func *=( A: inout matrix_float4x4, B: matrix_float4x4 )
	{
		A = matrix_multiply(A,B)
	}
	
	/// Performs a matrix multiplication of type y = A * x
	
	public static func *( A: matrix_float4x4, x: float4 ) -> float4
	{
		return matrix_multiply(A,x)
	}

}


//----------------------------------------------------------------------------------------------------------------------
