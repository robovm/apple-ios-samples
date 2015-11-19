/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `NSPredicate+Condition` properties and methods are used to parse the conditions used in `HMEventTrigger`s.
*/

import HomeKit

/// Represents condition type in HomeKit with associated values.
enum HomeKitConditionType {
    /**
        Represents a characteristic condition.
        
        The tuple represents the `HMCharacteristic` and its condition value.
        For example, "Current gargage door is set to 'Open'".
    */
    case Characteristic(HMCharacteristic, NSCopying)
    
    /**
        Represents a time condition.
        
        The tuple represents the time ordering and the sun state.
        For example, "Before sunset".
    */
    case SunTime(TimeConditionOrder, TimeConditionSunState)
    
    /**
        Represents an exact time condition.
        
        The tuple represents the time ordering and time.
        For example, "At 12:00pm".
    */
    case ExactTime(TimeConditionOrder, NSDateComponents)
    
    /// The predicate is not a HomeKit condition.
    case Unknown
}

extension NSPredicate {
    
    /**
        Parses the predicate and attempts to generate a characteristic-value tuple.
        
        - returns:  An optional characteristic-value tuple.
    */
    private func characteristicPair() -> (HMCharacteristic, NSCopying)? {
        guard let predicate = self as? NSCompoundPredicate else { return nil }
        guard let subpredicates = predicate.subpredicates as? [NSPredicate] else { return nil }
        guard subpredicates.count == 2 else { return nil }
        
        var characteristicPredicate: NSComparisonPredicate? = nil
        var valuePredicate: NSComparisonPredicate? = nil
        
        for subpredicate in subpredicates {
            if let comparison = subpredicate as? NSComparisonPredicate where comparison.leftExpression.expressionType == .KeyPathExpressionType && comparison.rightExpression.expressionType == .ConstantValueExpressionType {
                switch comparison.leftExpression.keyPath {
                    case HMCharacteristicKeyPath:
                        characteristicPredicate = comparison
                        
                    case HMCharacteristicValueKeyPath:
                        valuePredicate = comparison
                        
                    default:
                        break
                }
            }
        }
        
        if let characteristic = characteristicPredicate?.rightExpression.constantValue as? HMCharacteristic,
            characteristicValue = valuePredicate?.rightExpression.constantValue as? NSCopying {
                return (characteristic, characteristicValue)
        }
        return nil
    }
    
    /**
        Parses the predicate and attempts to generate an order-sunstate tuple.
        
        - returns:  An optional order-sunstate tuple.
    */
    private func sunStatePair() -> (TimeConditionOrder, TimeConditionSunState)? {
        guard let comparison = self as? NSComparisonPredicate else { return nil }
        guard comparison.leftExpression.expressionType == .KeyPathExpressionType else { return nil }
        guard comparison.rightExpression.expressionType == .FunctionExpressionType else { return nil }
        guard comparison.rightExpression.function == "now" else { return nil }
        guard comparison.rightExpression.arguments?.count == 0 else { return nil }
        
        switch (comparison.leftExpression.keyPath, comparison.predicateOperatorType) {
            case (HMSignificantEventSunrise, .LessThanPredicateOperatorType):
                return (.After, .Sunrise)
                
            case (HMSignificantEventSunrise, .LessThanOrEqualToPredicateOperatorType):
                return (.After, .Sunrise)
                
            case (HMSignificantEventSunrise, .GreaterThanPredicateOperatorType):
                return (.Before, .Sunrise)
                
            case (HMSignificantEventSunrise, .GreaterThanOrEqualToPredicateOperatorType):
                return (.Before, .Sunrise)
                
            case (HMSignificantEventSunset, .LessThanPredicateOperatorType):
                return (.After, .Sunset)
                
            case (HMSignificantEventSunset, .LessThanOrEqualToPredicateOperatorType):
                return (.After, .Sunset)
                
            case (HMSignificantEventSunset, .GreaterThanPredicateOperatorType):
                return (.Before, .Sunset)
                
            case (HMSignificantEventSunset, .GreaterThanOrEqualToPredicateOperatorType):
                return (.Before, .Sunset)
                
            default:
                return nil
        }
    }
    
    /**
        Parses the predicate and attempts to generate an order-exacttime tuple.
        
        - returns:  An optional order-exacttime tuple.
    */
    private func exactTimePair() -> (TimeConditionOrder, NSDateComponents)? {
        guard let comparison = self as? NSComparisonPredicate else { return nil }
        guard comparison.leftExpression.expressionType == .FunctionExpressionType else { return nil }
        guard comparison.leftExpression.function == "now" else { return nil }
        guard comparison.rightExpression.expressionType == .ConstantValueExpressionType else { return nil }
        guard let dateComponents = comparison.rightExpression.constantValue as? NSDateComponents else { return nil }
        
        switch comparison.predicateOperatorType {
            case .LessThanPredicateOperatorType, .LessThanOrEqualToPredicateOperatorType:
                return (.Before, dateComponents)
            
            case .GreaterThanPredicateOperatorType, .GreaterThanOrEqualToPredicateOperatorType:
                return (.After, dateComponents)
            
            case .EqualToPredicateOperatorType:
                return (.At, dateComponents)
            
            default:
                return nil
        }
    }
    
    /// - returns:  The 'type' of HomeKit condition, with associated value, if applicable.
    var homeKitConditionType: HomeKitConditionType {
        if let characteristicPair = characteristicPair() {
            return .Characteristic(characteristicPair)
        }
        else if let sunStatePair = sunStatePair() {
            return .SunTime(sunStatePair)
        }
        else if let exactTimePair = exactTimePair() {
            return .ExactTime(exactTimePair)
        }
        else {
            return .Unknown
        }
    }
}