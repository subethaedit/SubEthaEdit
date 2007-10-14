#ifndef _LLST_FW_Function
#define _LLST_FW_Function
/**
 * Function objects whose parameters may be read or changed
 * using get/setParameters.
 *
 * These are simple templated functors with the restriction that
 * their arguments, parameters and output must all be of the same type.
 * They were designed for use with the Kernel class.
 *
 * To create a function for a particular equation, subclass Function
 * or one its subclasses. Your subclass must:
 * - Have one or more constructors, all of which must initialize _params
 * - Define operator() with code to compute the function
 *   using this->_params or getParams to reference it
 *
 * A planned addition is to be able to construct separable functions
 * from existing Function1 functions (with no subclassing).
 */
#include <stdexcept>
#include <sstream>
#include <vector>

namespace lsst {
namespace fw {

/**
 * Basic Function class.
 */
template<class T>
class Function
{

public:
    Function(unsigned nParams) : _params(nParams) {};
    Function(std::vector<T> const &params) : _params(params) {};

    virtual const unsigned getNParameters() const {
        return _params.size();
    }
    virtual const std::vector<T> & getParameters() const {
        return _params;
    }
    virtual void setParameters(std::vector<T> const &params) {
        if (_params.size() != params.size()) {
            std::ostringstream errStream;
            errStream << "setParameters called with " << params.size() << 
                " parameters instead of " << _params.size() << std::endl;
            throw std::invalid_argument(errStream.str());
        }
        _params = params;
    }

protected:
    std::vector<T> _params;
};


/**
 * A Function taking one argument.
 */
template<class T>
class Function1 : public Function<T>
{
public:
    Function1(unsigned nParams) : Function<T>(nParams) {};
    Function1(std::vector<T> const &params) : Function<T>(params) {};

    virtual T operator() (T x) const = 0;
};


/**
 * A Function taking two arguments.
 */
template<class T>
class Function2 : public Function<T>
{
public:
    Function2(unsigned nParams) : Function<T>(nParams) {};
    Function2(std::vector<T> const &params) : Function<T>(params) {};

    virtual T operator() (T x, T y) const = 0;
};


}   // namespace lsst::fw
}   // namespace lsst

#endif // #ifndef _LLST_FW_Function
