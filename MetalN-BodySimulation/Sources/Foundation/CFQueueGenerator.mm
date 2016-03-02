/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A functor for creating dispatch queue with a unique identifier.
 */

#import <random>
#import <strstream>

#import "CFQueueGenerator.h"

@implementation CFQueueGenerator
{
@private
    // Dispatch queue id.
    uint64_t mnQID;
    
    // Desired dispatch queue attribute.
    dispatch_queue_attr_t _attribute;
    
    // Dispatch queue label.
    std::string m_Label;
    
    // Dispatch queue label plus an attched id.
    std::string m_SQID;
    
    // A device for random number generation
    std::random_device m_Device;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        // Initialize queue id
        mnQID = 0;
        
        // Initialize with an empty string
        m_SQID  = "";
        m_Label = "";

        // Default dispatch queue attribute is for a serial queue.
        _attribute = DISPATCH_QUEUE_SERIAL;
    } // if
    
    return self;
} // init

- (void) setLabel:(nullable const char *)label
{
    if(label != nullptr)
    {
        m_Label = label;
    } // if
} // setLabel

- (nullable const char*) identifier
{
    return m_SQID.c_str();
} // identifier

- (nullable dispatch_queue_t) queue
{
    mnQID = m_Device();

    std::strstream sqid;
    
    sqid << mnQID;
    
    if(m_Label.empty())
    {
        m_SQID = sqid.str();
    } // if
    else
    {
        m_SQID  = m_Label + ".";
        m_SQID += sqid.str();
    } // else
    
    m_SQID += "\0";
    
    return dispatch_queue_create(m_SQID.c_str(), _attribute);
} // queue

@end
