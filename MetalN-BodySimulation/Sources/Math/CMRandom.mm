/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for generating random values using uniform real distribution for a simd float3 vector with a least upper bound and a greatest lower bound.
 */

#import "CMNumerics.h"
#import "CMRandom.h"

#pragma mark -
#pragma mark Private - Interfaces

namespace CM
{
    namespace URD3
    {
        // Base class for generating uniform random distribution triplets
        class core
        {
        public:
            // Instantiate the object using a least uppper bound
            // and a greatest lower bound
            core(const float& min = 0.0f,
                 const float& max = 1.0f);
            
            // Copy constructor
            core(const core& rObject);
            
            // Destructor
            virtual ~core();
            
            // Assignment operator
            core& operator=(const core& rObject);
            
            // Get the greatest lower bound
            const float min() const;
            
            // Get the least upper bound
            const float max() const;
            
            // Tolerance for the Euclidean 2-norm
            const float eps() const;
            
            // Upper bound for the Euclidean 2-norm
            const float length() const;
            
            // Set the tolerance for the Euclidean 2-norm
            void setEPS(const float& eps);
            
            // Set the length for bounding metric
            void setLength(const float& len);
            
            // Reset the distribution such that subsequent values generated
            // are independent of previously generated values
            void reset();
            
            // Uniform real distribution triplets
            virtual simd::float3 rand() = 0;
            
            // Normalized uniform real distribution triplets
            virtual simd::float3 nrand() = 0;
            
        protected:
            float  mnEPS;   // Tolerance for the bounding value of 2-norm metric
            float  mnLen;   // Bounding value for 2-norm metric
            float  mnMin;   // Greatest lower bound for uniform integer generator
            float  mnMax;   // Least upper bound for uniform integer generator
            
            // Uniform discrete real generator:
            //
            // <http://www.cplusplus.com/reference/random/uniform_real_distribution/>
            //
            // The valid type names here are float, double, or long double.
            std::default_random_engine             m_Generator;
            std::uniform_real_distribution<float>  m_Distribution;
        }; // core
        
        // Uniform real distribution triplets bounded by a 2-norm metric
        class bounded: public core
        {
        public:
            bounded(const float& min = 0.0f,
                    const float& max = 1.0f);
            
            bounded(const bounded& rObject);
            
            bounded& operator=(const bounded& rObject);
            
            virtual ~bounded();
            
            simd::float3 rand();
            simd::float3 nrand();
        }; // bounded
        
        // Uniform real distribution triplets without a bounding metric
        class unbounded: public core
        {
        public:
            unbounded(const float& min = 0.0f,
                      const float& max = 1.0f);
            
            unbounded(const unbounded& rObject);
            
            unbounded& operator=(const unbounded& rObject);
            
            virtual ~unbounded();
            
            simd::float3 rand();
            simd::float3 nrand();
        }; // unbounded
        
        // A constructor for  creating a uniform real distribution
        // triplets with/without a bounding metric
        core* create(const float& min,
                     const float& max,
                     const float& len,
                     const float& eps);
        
        // A copy constructor for  creating a uniform real distribution
        // triplets with/without a bounding metric
        core* createCopy(const core* const pCoreSrc);
    } // URD3
} // CM

#pragma mark -
#pragma mark Private - Implementation - Core

//---------------------------------------------------------------
//
// Base class for generating uniform random distribution triplets
//
//---------------------------------------------------------------

// Instantiate the object using a least uppper bound
// and a greatest lower bound
CM::URD3::core::core(const float& min,
                     const float& max)
{
    // Default bounds for the uniform real distribution
    mnMin = min;
    mnMax = max;
    
    // Initialize the bounding metric 2-norm maximum
    mnEPS = 1e-6;
    mnLen = 0.0;
    
    // Acquire a random device for initializing our engine
    std::random_device  device;
    
    // Initialize the uniform real distribution for
    // random number generation
    m_Generator    = std::default_random_engine(device());
    m_Distribution = std::uniform_real_distribution<float>(mnMin, mnMax);
} // Constructor

// Copy constructor
CM::URD3::core::core(const core& rObject)
{
    mnMin = rObject.mnMin;
    mnMax = rObject.mnMax;
    
    m_Generator    = rObject.m_Generator;
    m_Distribution = rObject.m_Distribution;
} // Copy Constructor

// Destructor
CM::URD3::core::~core()
{
    mnMin = 0.0f;
    mnMax = 0.0f;
    
    m_Distribution.reset();
} // Destructor

// Assignment operator
CM::URD3::core& CM::URD3::core::operator=(const core& rObject)
{
    if(this != &rObject)
    {
        mnMin = rObject.mnMin;
        mnMax = rObject.mnMax;
        mnLen = rObject.mnLen;
        mnEPS = rObject.mnEPS;
        
        m_Generator    = rObject.m_Generator;
        m_Distribution = rObject.m_Distribution;
    } // if
    
    return *this;
} // Assignment Operator

// Tolerance for the Euclidean 2-norm
const float CM::URD3::core::eps() const
{
    return mnEPS;
} // eps

// Upper bound for the Euclidean 2-norm
const float CM::URD3::core::length() const
{
    return mnLen;
} // length

// Get the greatest lower bound
const float CM::URD3::core::min() const
{
    return mnMin;
} // min

// Get the least upper bound
const float CM::URD3::core::max() const
{
    return mnMax;
} // max

// Reset the distribution such that subsequent values generated
// are independent of previously generated values
void CM::URD3::core::reset()
{
    m_Distribution.reset();
} // reset

// Set the length for bounding metric
void CM::URD3::core::setLength(const float& len)
{
    mnLen = len;
} // setLength

// Set the tolerance for the Euclidean 2-norm
void CM::URD3::core::setEPS(const float& eps)
{
    mnEPS = eps;
} // setEPS

#pragma mark -
#pragma mark Private - Implementation - Bounded

//--------------------------------------------------------------
//
// Uniform real distribution triplets bounded by a 2-norm metric
//
//--------------------------------------------------------------

CM::URD3::bounded::bounded(const float& min,
                           const float& max)
: CM::URD3::core::core(min, max)
{
    
} // constructor

CM::URD3::bounded::~bounded()
{
    
} // destructor

CM::URD3::bounded::bounded(const bounded& rObject)
: CM::URD3::core::core(rObject)
{
    
} // Copy constructor

CM::URD3::bounded& CM::URD3::bounded::operator=(const bounded& rObject)
{
    if(this != &rObject)
    {
        this->CM::URD3::core::operator=(rObject);
    } // if
    
    return *this;
} // Assignment Operator

// Concrete implementation for generating uniform real distribution
// triplets
simd::float3 CM::URD3::bounded::rand()
{
    simd::float3 rand = 0.0f;
    
    float norm = 0.0f;
    
    do
    {
        rand.x = m_Distribution(m_Generator);
        rand.y = m_Distribution(m_Generator);
        rand.z = m_Distribution(m_Generator);
        
        norm = simd::length(rand);
    }
    while(norm > mnLen);
    
    return rand;
} // rand

// Concrete implementation for generating normalized uniform real
// distribution triplets
simd::float3 CM::URD3::bounded::nrand()
{
    return simd::normalize(CM::URD3::bounded::rand());
} // nrand

#pragma mark -
#pragma mark Private - Implementation - Unbounded

//--------------------------------------------------------------
//
// Uniform real distribution triplets without a bounding metric
//
//--------------------------------------------------------------

CM::URD3::unbounded::unbounded(const float& min,
                               const float& max)
: CM::URD3::core::core(min, max)
{
    
} // constructor

CM::URD3::unbounded::~unbounded()
{
    
} // destructor

CM::URD3::unbounded::unbounded(const unbounded& rObject)
: CM::URD3::core::core(rObject)
{
    
} // Copy constructor

CM::URD3::unbounded& CM::URD3::unbounded::operator=(const unbounded& rObject)
{
    if(this != &rObject)
    {
        this->CM::URD3::core::operator=(rObject);
    } // if
    
    return *this;
} // Assignment Operator

// Concrete implementation for generating uniform real distribution
// triplets
simd::float3 CM::URD3::unbounded::rand()
{
    simd::float3 rand = 0.0f;
    
    rand.x = m_Distribution(m_Generator);
    rand.y = m_Distribution(m_Generator);
    rand.z = m_Distribution(m_Generator);
    
    return rand;
} // rand

// Concrete implementation for generating normalized uniform real
// distribution triplets
simd::float3 CM::URD3::unbounded::nrand()
{
    return simd::normalize(CM::URD3::unbounded::rand());
} // nrand

#pragma mark -
#pragma mark Private - Utilities

// A constructor for  creating a uniform real distribution
// triplets with/without a bounding metric
CM::URD3::core* CM::URD3::create(const float& min,
                                 const float& max,
                                 const float& len,
                                 const float& eps)
{
    CM::URD3::core* pCore = nullptr;
    
    float nLen = len;
    float nEPS = eps;
    
    if(CM::isZero(nLen, nEPS))
    {
        pCore = new (std::nothrow) CM::URD3::unbounded(min, max);
    } // if
    else
    {
        pCore = new (std::nothrow) CM::URD3::bounded(min, max);
    } // else
    
    if(pCore != nullptr)
    {
        pCore->setLength(nLen);
        pCore->setEPS(nEPS);
    } // if
    
    return pCore;
} // CMURD3CoreCreate

// A copy constructor for  creating a uniform real distribution
// triplets with/without a bounding metric
CM::URD3::core* CM::URD3::createCopy(const core* const pCoreSrc)
{
    CM::URD3::core* pCoreDst = nullptr;
    
    if(pCoreSrc != nullptr)
    {
        float nLen = pCoreSrc->length();
        float nEPS = pCoreSrc->eps();
        float nMin = pCoreSrc->min();
        float nMax = pCoreSrc->max();
        
        pCoreDst = CM::URD3::create(nMin, nMax, nLen, nEPS);
    } // if
    
    return pCoreDst;
} // CMURD3CoreCreateCopy

#pragma mark -
#pragma mark Public - Implementation - Generator

//-------------------------------------------------------------------------
//
// Uniform real distribution facade for generating triplets with/without
// a bounding metric.
//
//-------------------------------------------------------------------------

// Instantiate the object using a least uppper bound and a greatest lower
// bound. If the length is a value greter than zero, then the object will
// generate uniform real distribution triplets bounded by a 2-norm metric.
// Otherwise, the instantiated object generates uniform real distribution
// triplets without a bounding metric.
CM::URD3::generator::generator(const float& min,
                               const float& max,
                               const float& len,
                               const float& eps)
{
    mpCore = CM::URD3::create(min, max, len, eps);
} // Constructor

// Copy constructor
CM::URD3::generator::generator(const generator& rObject)
{
    mpCore = CM::URD3::createCopy(rObject.mpCore);
} // Copy Constructor

// Destructor
CM::URD3::generator::~generator()
{
    if(mpCore != nullptr)
    {
        delete mpCore;
        
        mpCore = nullptr;
    } // if
} // Destructor

// Assignment operator
CM::URD3::generator& CM::URD3::generator::operator=(const generator& rObject)
{
    if(this != &rObject)
    {
        CM::URD3::core* pCore = CM::URD3::createCopy(rObject.mpCore);
        
        if(pCore != nullptr)
        {
            if(mpCore != nullptr)
            {
                delete mpCore;
                
                mpCore = nullptr;
            } // if
            
            mpCore = pCore;
        } // if
    } // if
    
    return *this;
} // Assignment Operator

// Get the greatest lower bound
const float CM::URD3::generator::min() const
{
    return mpCore->min();
} // min

// Get the least upper bound
const float CM::URD3::generator::max() const
{
    return mpCore->max();
} // max

// Reset the distribution such that subsequent values generated
// are independent of previously generated values
void CM::URD3::generator::reset()
{
    mpCore->reset();
} // reser

// Uniform real distribution triplets
simd::float3 CM::URD3::generator::rand()
{
    return mpCore->rand();
} // rand

// Normalized uniform real distribution triplets
simd::float3 CM::URD3::generator::nrand()
{
    return mpCore->nrand();
} // nrand

#pragma mark -
#pragma mark Public - Utilities

// Constructor method for creating a shared pointer.  If the length is
// a value greter than zero, then the shared pointer returned will
// be for the utility class for generating uniform real distribution
// triplets bounded by a 2-norm metric. Otherwise, the shared pointer
// returned will be for the utility class generating uniform real
// distribution triplets without a bounding metric.
std::shared_ptr<CM::URD3::generator> CM::URD3::shared_ptr(const float& min,
                                                          const float& max,
                                                          const float& len,
                                                          const float& eps)
{
    return std::shared_ptr<CM::URD3::generator>(new (std::nothrow) CM::URD3::generator(min, max, len, eps));
} // shared_ptr

// Constructor method for creating a unique pointer.  If the length is
// a value greter than zero, then the unique pointer returned will
// be for the utility class for generating uniform real distribution
// triplets bounded by a 2-norm metric. Otherwise, the unique pointer
// returned will be for the utility class generating uniform real
// distribution triplets without a bounding metric.
std::unique_ptr<CM::URD3::generator> CM::URD3::unique_ptr(const float& min,
                                                          const float& max,
                                                          const float& len,
                                                          const float& eps)
{
    return std::unique_ptr<CM::URD3::generator>(new (std::nothrow) CM::URD3::generator(min, max, len, eps));
} // unique_ptr
