<?php
//- mark classes with final statement
//- mark

final class BaseClass {
   public function test() {
       echo "BaseClass::test() called\n";
   }

   // Here it doesn't matter if you specify the function as final or not
   final public function moreTesting() {
       echo "BaseClass::moreTesting() called\n";
   }
}

class ChildClass extends BaseClass {
}
// Results in Fatal error: Class ChildClass may not inherit from final class (BaseClass)
?>

<?php

class BaseClass {
   public function test() {
       echo "BaseClass::test() called\n";
   }
   
   final public function moreTesting() {
       echo "BaseClass::moreTesting() called\n";
   }
}

class ChildClass extends BaseClass {
   public function moreTesting() {
       echo "ChildClass::moreTesting() called\n";
   }
}
// Results in Fatal error: Cannot override final method BaseClass::moreTesting()
?>

<?php
//- mark
//- mark Cloning
//- mark

class SubObject
{
   static $instances = 0;
   public $instance;

   public function __construct() {
       $this->instance = ++self::$instances;
   }

   public function __clone() {
       $this->instance = ++self::$instances;
   }
}

class MyCloneable
{
   public $object1;
   public $object2;

   function __clone()
   {
       // Force a copy of this->object, otherwise
       // it will point to same object.
       $this->object1 = clone($this->object1);
   }
}

$obj = new MyCloneable();

$obj->object1 = new SubObject();
$obj->object2 = new SubObject();

$obj2 = clone $obj;


print("Original Object:\n");
print_r($obj);

print("Cloned Object:\n");
print_r($obj2);

?>

<?php
//- mark
//- mark Magic Methods
//- mark

class BetterClass
{
  private $content;

  public function __sleep()
  {
   return array('basedata1', 'basedata2');
  }

  public function getContents() { ...stuff... }
}

class BetterDerivedClass extends BetterClass
{
  private $decrypted_block;

  public function __sleep()
  {
   return parent::__sleep();
  }

  public function getContents() { ...decrypt... }
}

?>
<?php
//- mark
function __autoload($class_name) {
   require_once $class_name . '.php';
}

$obj  = new MyClass1();
$obj2 = new MyClass2(); 
?>

<?php
//- mark
//- mark visibility
//- mark
/**
 * Define MyClass
 */
class MyClass
{
   public $public = 'Public';
   protected $protected = 'Protected';
   private $private = 'Private';

   function printHello()
   {
       echo $this->public;
       echo $this->protected;
       echo $this->private;
   }
}

$obj = new MyClass();
echo $obj->public; // Works
echo $obj->protected; // Fatal Error
echo $obj->private; // Fatal Error
$obj->printHello(); // Shows Public, Protected and Private


/**
 * Define MyClass2
 */
class MyClass2 extends MyClass
{
   // We can redeclare the public and protected method, but not private
   protected $protected = 'Protected2';

   function printHello()
   {
       echo $this->public;
       echo $this->protected;
       echo $this->private;
   }
}

$obj2 = new MyClass2();
echo $obj->public; // Works
echo $obj2->private; // Undefined
echo $obj2->protected; // Fatal Error
$obj2->printHello(); // Shows Public, Protected2, not Private

?>
<?php
/**
 * Define MyClass
 */
class MyClass
{
   // Contructors must be public
   public function __construct() { }

   // Declare a public method
   public function MyPublic() { }

   // Declare a protected method
   protected function MyProtected() { }

   // Declare a private method
   private function MyPrivate() { }

   // This is public
   function Foo()
   {
       $this->MyPublic();
       $this->MyProtected();
       $this->MyPrivate();
   }
}

$myclass = new MyClass;
$myclass->MyPublic(); // Works
$myclass->MyProtected(); // Fatal Error
$myclass->MyPrivate(); // Fatal Error
$myclass->Foo(); // Public, Protected and Private work


/**
 * Define MyClass2
 */
class MyClass2 extends MyClass
{
   // This is public
   function Foo2()
   {
       $this->MyPublic();
       $this->MyProtected();
       $this->MyPrivate(); // Fatal Error
   }
}

$myclass2 = new MyClass2;
$myclass2->MyPublic(); // Works
$myclass2->Foo2(); // Public and Protected work, not Private
?>
