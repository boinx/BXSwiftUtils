//
//  String+UniqueByIncrementing.swift
//  BXSwiftUtils
//
//  Created by Stefan Fochler on 11.09.18.
//  Copyright © 2018 Boinx Software Ltd. & Imagine GbR. All rights reserved.
//

import Foundation

extension String
{
    /**
     Returns a collision-free version of the string by incrementing a counter that is appended to the string until the
     rejector check passes.
     
     This function can be used in multiple ways:
     
     - Name multiple instances of the same base name without confusing the user, e.g.:
     
           "Placer 3" == "Placer".uniqueStringByIncrementing(rejectIf: ["Placer", "Placer 2"].contains)
    
     - Name copies of existing instances by appending an annotation (e.g. "copy") and incrementing the counter, even if
       the user choses to duplicate a copy itself, e.g.:
     
           "Placer Copy" == "Placer".uniqueStringByIncrementing(rejectIf: ["Placer"].contains, appendAnnotation: "Copy")
           "Placer Copy 3" == "Placer Copy 2".uniqueStringByIncrementing(rejectIf: ["Placer Copy 2"].contains, appendAnnotation: "Copy")
     
     **Note**: Incrementing an existing counter is only possible when starting from the base name (see first use case),
     or using an annotation before the counter (see second use case). Thus:
     
         "Placer 3 2" == "Placer 3".uniqueStringByIncrementing(rejectIf: ["Placer 3"].contains)
     
     - parameter rejector: Function that has to return `false` for already existing suggestions and `true` for valid
                           suggestions. Can be `someArray.contains`, as seen in the examples, or some other, more
                           dynamic function.
     - parameter suggestion: Suggested name that should be checked for uniqueness.
     - parameter appendAnnotation: String that gets appended, e.g. "copy". Only when given an annotation, the function
                                   will attempt to increment an existing counter. Otherwise, a new counter will be
                                   attached to the input string. Defaults to `nil``.
     - parameter separator: Character or string that separates the base name from the annotation and the counter.
                            Defaults to `" "`.
     */
    public func uniqueStringByIncrementing(rejectIf rejector: (_ suggestion: String) -> Bool, appendAnnotation: String? = nil, separator: String = " ") -> String
    {
        // If append exists, prefix it with a space so it's safe to append to the basename.
        // If it doesn't exist, make it an empty string, which is safe to insert, too.
        let appendSafeAnnotation = appendAnnotation.map { separator + $0 } ?? ""
        
        var workingName = self
        var workingCounter = 1
        
        // If we are using an annotation (such as "copy"), we want to be a bit smarter about the collision avoidance by
        // checking if "<annotation> <counter>" already exists, and using the new counter value from then on.
        // However, if there is no annotation, then we would mistakenly also increment inputs like "Show 2018", which
        // we mustn't do.
        if appendAnnotation != nil,
           let (base, counter) = self.separatedBaseAndCounter(for: appendSafeAnnotation, separator: separator)
        {
            workingName = base
            workingCounter = counter
        }
        
        // Create candidate strings until one of them does not collide with an existing name.
        return (workingCounter ..< .max)
            .lazy
            .map(
            { counter in
                var composedString = "\(workingName)\(appendSafeAnnotation)"
                
                // Counter is only appended for values 2 and higher, because every string is implicitly numbered "1".
                if counter >= 2 {
                    composedString += "\(separator)\(counter)"
                }
                
                return composedString
            })
            .first(where: { !rejector($0) })!
    }
    
    /**
     Same as `uniqueStringByIncrementing(rejectIf:appendAnnotation:separator)`, except that the string can end with a
     single file extension.
     */
    public func uniqueFilenameByIncrementing(rejectIf rejector: (_ suggestion: String) -> Bool, appendAnnotation: String? = nil, separator: String = " ") -> String
    {
        let nsString = self as NSString
        
        let fileExtension = nsString.pathExtension
        let fileName = nsString.deletingPathExtension
        
        let collisionFreeName = fileName.uniqueStringByIncrementing(rejectIf: { rejector("\($0).\(fileExtension)") }, appendAnnotation: appendAnnotation, separator: separator)
        
        return "\(collisionFreeName).\(fileExtension)"
        
    }
    
    fileprivate func separatedBaseAndCounter(for annotation: String, separator: String) -> (base: String, counter: Int)?
    {
        // Dynamic input that appears in a regular expression? Better escape it.
        let escapedAnnotation = NSRegularExpression.escapedPattern(for: annotation)
        let escapedSeparator = NSRegularExpression.escapedPattern(for: separator)
        
        // Try to find match of the annotation and, optionally, the separator and counter digits.
        if let matchedRange = self.range(of: "\(escapedAnnotation)(\(escapedSeparator)\\d+)?$", options: [.regularExpression])
        {
            // Portion of the matched string that contains the counter (may be empty, so assume 1 if parsing fails)
            let counterString = self[matchedRange].dropFirst(annotation.count + separator.count)
            let counterValue = Int(counterString) ?? 1
            
            return (
                base: String(self[self.startIndex ..< matchedRange.lowerBound]),
                counter: counterValue
            )
        }
        
        return nil
    }
}


// The Objective C Methods are prefixed with objc_ to avoid an infitite recursion when calling the equally named swift
// method. Although this can be prevented by correctly converting all parameter types, it's super easy to miss...
extension NSString
{
    @objc public func objc_uniqueStringByIncrementing(rejectIf rejector: (_ suggestion: NSString) -> Bool, appendAnnotation: NSString? = nil, separator: NSString = " ") -> NSString
    {
        return (self as String).uniqueStringByIncrementing(rejectIf: { rejector($0 as NSString) }, appendAnnotation: appendAnnotation as String?, separator: separator as String) as NSString
    }
    
    @objc public func objc_uniqueFilenameByIncrementing(rejectIf rejector: (_ suggestion: NSString) -> Bool, appendAnnotation: NSString? = nil, separator: NSString = " ") -> NSString
    {
        return (self as String).uniqueFilenameByIncrementing(rejectIf: { rejector($0 as NSString) }, appendAnnotation: appendAnnotation as String?, separator: separator as String) as NSString
    }
}
