JsOsaDAS1.001.00bplist00�Vscripto,� f u n c t i o n   s e e s c r i p t s e t t i n g s ( )   { 
 	 r e t u r n   { 
 	 	 d i s p l a y N a m e :   ' D e c o d e   Q u o t e d - P r i n t a b l e ' , 
 	 	 i n C o n t e x t M e n u :   ' y e s ' 
 	 } 
 } 
 
 f u n c t i o n   r u n ( )   { 
 	 l e t   s e e   =   A p p l i c a t i o n ( ' S u b E t h a E d i t ' ) 
 	 l e t   a p p   =   A p p l i c a t i o n . c u r r e n t A p p l i c a t i o n ( ) 
 	 a p p . i n c l u d e S t a n d a r d A d d i t i o n s   =   t r u e 
 
 	 i f   ( s e e . d o c u m e n t s . l e n g t h   = =   0 )   { 
 	 	 r e t u r n 
 	 } 
     
     t r y   { 
         l e t   d o c u m e n t   =   s e e . d o c u m e n t s [ 0 ] 
         l e t   h a s S e l e c t i o n   =   ( s e e . s e l e c t i o n ( ) ? . c o n t e n t s ( ) ? . l e n g t h   >   0 ) 
         l e t   s o m e T e x t ; 
         i f   ( h a s S e l e c t i o n )   { 
             s o m e T e x t   =   s e e . s e l e c t i o n ( ) . c o n t e n t s ( ) 
         }   e l s e   { 
             s o m e T e x t   =   d o c u m e n t . c o n t e n t s ( ) 
         } 
 
         v a r   c h a n g e d T e x t   =   u t f 8 . d e c o d e ( q u o t e d P r i n t a b l e . d e c o d e ( s o m e T e x t ) ) 
 
         i f   ( h a s S e l e c t i o n )   { 
             d o c u m e n t . s e l e c t i o n ( ) . c o n t e n t s   =   c h a n g e d T e x t 
         }   e l s e   { 
             d o c u m e n t . c o n t e n t s   =   c h a n g e d T e x t 
         } 
     }   c a t c h   ( e )   { 
         a p p . d i s p l a y A l e r t ( ' A n   e r r o r   o c c u r e d ' ,   {   
             m e s s a g e :   ` $ { e . m e s s a g e }   ( l i n e :   $ { e . l i n e } ) ` ,   
             a s :   ' c r i t i c a l ' , 
             b u t t o n :   ' O K ' 
         } ) 
     } 
 } 
 
 / * !   h t t p s : / / m t h s . b e / q u o t e d - p r i n t a b l e   v < % =   v e r s i o n   e 5 7 5 2 a 4   % >   b y   @ m a t h i a s   |   M I T   l i c e n s e   * / 
 ; ( f u n c t i o n ( r o o t )   { 
 
 	 / /   D e t e c t   f r e e   v a r i a b l e s   ` e x p o r t s ` . 
 	 v a r   f r e e E x p o r t s   =   t y p e o f   e x p o r t s   = =   ' o b j e c t '   & &   e x p o r t s ; 
 
 	 / /   D e t e c t   f r e e   v a r i a b l e   ` m o d u l e ` . 
 	 v a r   f r e e M o d u l e   =   t y p e o f   m o d u l e   = =   ' o b j e c t '   & &   m o d u l e   & & 
 	 	 m o d u l e . e x p o r t s   = =   f r e e E x p o r t s   & &   m o d u l e ; 
 
 	 / /   D e t e c t   f r e e   v a r i a b l e   ` g l o b a l ` ,   f r o m   N o d e . j s   o r   B r o w s e r i f i e d   c o d e ,   a n d   u s e 
 	 / /   i t   a s   ` r o o t ` . 
 	 v a r   f r e e G l o b a l   =   t y p e o f   g l o b a l   = =   ' o b j e c t '   & &   g l o b a l ; 
 	 i f   ( f r e e G l o b a l . g l o b a l   = = =   f r e e G l o b a l   | |   f r e e G l o b a l . w i n d o w   = = =   f r e e G l o b a l )   { 
 	 	 r o o t   =   f r e e G l o b a l ; 
 	 } 
 
 	 / * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - * / 
 
 	 v a r   s t r i n g F r o m C h a r C o d e   =   S t r i n g . f r o m C h a r C o d e ; 
 	 v a r   d e c o d e   =   f u n c t i o n ( i n p u t )   { 
 	 	 r e t u r n   i n p u t 
 	 	 	 / /   h t t p s : / / t o o l s . i e t f . o r g / h t m l / r f c 2 0 4 5 # s e c t i o n - 6 . 7 ,   r u l e   3 : 
 	 	 	 / /    T h e r e f o r e ,   w h e n   d e c o d i n g   a   ` Q u o t e d - P r i n t a b l e `   b o d y ,   a n y   t r a i l i n g   w h i t e 
 	 	 	 / /   s p a c e   o n   a   l i n e   m u s t   b e   d e l e t e d ,   a s   i t   w i l l   n e c e s s a r i l y   h a v e   b e e n   a d d e d 
 	 	 	 / /   b y   i n t e r m e d i a t e   t r a n s p o r t   a g e n t s .  
 	 	 	 . r e p l a c e ( / [ \ t \ x 2 0 ] $ / g m ,   ' ' ) 
 	 	 	 / /   R e m o v e   h a r d   l i n e   b r e a k s   p r e c e d e d   b y   ` = ` .   P r o p e r   ` Q u o t e d - P r i n t a b l e ` - 
 	 	 	 / /   e n c o d e d   d a t a   o n l y   c o n t a i n s   C R L F   l i n e     e n d i n g s ,   b u t   f o r   c o m p a t i b i l i t y 
 	 	 	 / /   r e a s o n s   w e   s u p p o r t   s e p a r a t e   C R   a n d   L F   t o o . 
 	 	 	 . r e p l a c e ( / = ( ? : \ r \ n ? | \ n | $ ) / g ,   ' ' ) 
 	 	 	 / /   D e c o d e   e s c a p e   s e q u e n c e s   o f   t h e   f o r m   ` = X X `   w h e r e   ` X X `   i s   a n y 
 	 	 	 / /   c o m b i n a t i o n   o f   t w o   h e x i d e c i m a l   d i g i t s .   F o r   o p t i m a l   c o m p a t i b i l i t y , 
 	 	 	 / /   l o w e r c a s e   h e x a d e c i m a l   d i g i t s   a r e   s u p p o r t e d   a s   w e l l .   S e e 
 	 	 	 / /   h t t p s : / / t o o l s . i e t f . o r g / h t m l / r f c 2 0 4 5 # s e c t i o n - 6 . 7 ,   n o t e   1 . 
 	 	 	 . r e p l a c e ( / = ( [ a - f A - F 0 - 9 ] { 2 } ) / g ,   f u n c t i o n ( $ 0 ,   $ 1 )   { 
 	 	 	 	 v a r   c o d e P o i n t   =   p a r s e I n t ( $ 1 ,   1 6 ) ; 
 	 	 	 	 r e t u r n   s t r i n g F r o m C h a r C o d e ( c o d e P o i n t ) ; 
 	 	 	 } ) ; 
 	 } ; 
 
 	 v a r   h a n d l e T r a i l i n g C h a r a c t e r s   =   f u n c t i o n ( s t r i n g )   { 
 	 	 r e t u r n   s t r i n g 
 	 	 	 . r e p l a c e ( / \ x 2 0 $ / ,   ' = 2 0 ' )   / /   H a n d l e   t r a i l i n g   s p a c e . 
 	 	 	 . r e p l a c e ( / \ t $ / ,   ' = 0 9 ' )   / /   H a n d l e   t r a i l i n g   t a b . 
 	 } ; 
 
 	 v a r   r e g e x U n s a f e S y m b o l s   =   / < % =   u n s a f e S y m b o l s   % > / g ; 
 	 v a r   e n c o d e   =   f u n c t i o n ( s t r i n g )   { 
 
 	 	 / /   E n c o d e   s y m b o l s   t h a t   a r e   d e f i n i t e l y   u n s a f e   ( i . e .   u n s a f e   i n   a n y   c o n t e x t ) . 
 	 	 v a r   e n c o d e d   =   s t r i n g . r e p l a c e ( r e g e x U n s a f e S y m b o l s ,   f u n c t i o n ( s y m b o l )   { 
 	 	 	 i f   ( s y m b o l   >   ' \ x F F ' )   { 
 	 	 	 	 t h r o w   R a n g e E r r o r ( 
 	 	 	 	 	 ' ` q u o t e d P r i n t a b l e . e n c o d e ( ) `   e x p e c t s   e x t e n d e d   A S C I I   i n p u t   o n l y .   '   + 
 	 	 	 	 	 ' D o n \ u 2 0 1 9 t   f o r g e t   t o   e n c o d e   t h e   i n p u t   f i r s t   u s i n g   a   c h a r a c t e r   '   + 
 	 	 	 	 	 ' e n c o d i n g   l i k e   U T F - 8 . ' 
 	 	 	 	 ) ; 
 	 	 	 } 
 	 	 	 v a r   c o d e P o i n t   =   s y m b o l . c h a r C o d e A t ( 0 ) ; 
 	 	 	 v a r   h e x a d e c i m a l   =   c o d e P o i n t . t o S t r i n g ( 1 6 ) . t o U p p e r C a s e ( ) ; 
 	 	 	 r e t u r n   ' = '   +   ( ' 0 '   +   h e x a d e c i m a l ) . s l i c e ( - 2 ) ; 
 	 	 } ) ; 
 
 	 	 / /   L i m i t   l i n e s   t o   7 6   c h a r a c t e r s   ( n o t   c o u n t i n g   t h e   C R L F   l i n e   e n d i n g s ) . 
 	 	 v a r   l i n e s   =   e n c o d e d . s p l i t ( / \ r \ n ? | \ n / g ) ; 
 	 	 v a r   l i n e I n d e x   =   - 1 ; 
 	 	 v a r   l i n e C o u n t   =   l i n e s . l e n g t h ; 
 	 	 v a r   r e s u l t   =   [ ] ; 
 	 	 w h i l e   ( + + l i n e I n d e x   <   l i n e C o u n t )   { 
 	 	 	 v a r   l i n e   =   l i n e s [ l i n e I n d e x ] ; 
 	 	 	 / /   L e a v e   r o o m   f o r   t h e   t r a i l i n g   ` = `   f o r   s o f t   l i n e   b r e a k s . 
 	 	 	 v a r   L I N E _ L E N G T H   =   7 5 ; 
 	 	 	 v a r   i n d e x   =   0 ; 
 	 	 	 v a r   l e n g t h   =   l i n e . l e n g t h ; 
 	 	 	 w h i l e   ( i n d e x   <   l e n g t h )   { 
 	 	 	 	 v a r   b u f f e r   =   e n c o d e d . s l i c e ( i n d e x ,   i n d e x   +   L I N E _ L E N G T H ) ; 
 	 	 	 	 / /   I f   t h i s   l i n e   e n d s   w i t h   ` = ` ,   o p t i o n a l l y   f o l l o w e d   b y   a   s i n g l e   u p p e r c a s e 
 	 	 	 	 / /   h e x a d e c i m a l   d i g i t ,   w e   b r o k e   a n   e s c a p e   s e q u e n c e   i n   h a l f .   F i x   i t   b y 
 	 	 	 	 / /   m o v i n g   t h e s e   c h a r a c t e r s   t o   t h e   n e x t   l i n e . 
 	 	 	 	 i f   ( / = $ / . t e s t ( b u f f e r ) )   { 
 	 	 	 	 	 b u f f e r   =   b u f f e r . s l i c e ( 0 ,   L I N E _ L E N G T H   -   1 ) ; 
 	 	 	 	 	 i n d e x   + =   L I N E _ L E N G T H   -   1 ; 
 	 	 	 	 }   e l s e   i f   ( / = [ A - F 0 - 9 ] $ / . t e s t ( b u f f e r ) )   { 
 	 	 	 	 	 b u f f e r   =   b u f f e r . s l i c e ( 0 ,   L I N E _ L E N G T H   -   2 ) ; 
 	 	 	 	 	 i n d e x   + =   L I N E _ L E N G T H   -   2 ; 
 	 	 	 	 }   e l s e   { 
 	 	 	 	 	 i n d e x   + =   L I N E _ L E N G T H ; 
 	 	 	 	 } 
 	 	 	 	 r e s u l t . p u s h ( b u f f e r ) ; 
 	 	 	 } 
 	 	 } 
 
 	 	 / /   E n c o d e   s p a c e   a n d   t a b   c h a r a c t e r s   a t   t h e   e n d   o f   e n c o d e d   l i n e s .   N o t e   t h a t 
 	 	 / /   w i t h   t h e   c u r r e n t   i m p l e m e n t a t i o n ,   t h i s   c a n   o n l y   o c c u r   a t   t h e   v e r y   e n d   o f 
 	 	 / /   t h e   e n c o d e d   s t r i n g      e v e r y   o t h e r   l i n e   e n d s   w i t h   ` = `   a n y w a y . 
 	 	 v a r   l a s t L i n e L e n g t h   =   b u f f e r . l e n g t h ; 
 	 	 i f   ( / [ \ t \ x 2 0 ] $ / . t e s t ( b u f f e r ) )   { 
 	 	 	 / /   T h e r e  s   a   s p a c e   o r   a   t a b   a t   t h e   e n d   o f   t h e   l a s t   e n c o d e d   l i n e .   R e m o v e 
 	 	 	 / /   t h i s   l i n e   f r o m   t h e   ` r e s u l t `   a r r a y ,   a s   i t   n e e d s   t o   c h a n g e . 
 	 	 	 r e s u l t . p o p ( ) ; 
 	 	 	 i f   ( l a s t L i n e L e n g t h   +   2   < =   L I N E _ L E N G T H   +   1 )   { 
 	 	 	 	 / /   I t  s   p o s s i b l e   t o   e n c o d e   t h e   c h a r a c t e r   w i t h o u t   e x c e e d i n g   t h e   l i n e 
 	 	 	 	 / /   l e n g t h   l i m i t . 
 	 	 	 	 r e s u l t . p u s h ( 
 	 	 	 	 	 h a n d l e T r a i l i n g C h a r a c t e r s ( b u f f e r ) 
 	 	 	 	 ) ; 
 	 	 	 }   e l s e   { 
 	 	 	 	 / /   I t  s   n o t   p o s s i b l e   t o   e n c o d e   t h e   c h a r a c t e r   w i t h o u t   e x c e e d i n g   t h e   l i n e 
 	 	 	 	 / /   l e n g t h   l i m i t .   R e m v o e   t h e   c h a r a c t e r   f r o m   t h e   l i n e ,   a n d   i n s e r t   a   n e w 
 	 	 	 	 / /   l i n e   t h a t   c o n t a i n s   o n l y   t h e   e n c o d e d   c h a r a c t e r . 
 	 	 	 	 r e s u l t . p u s h ( 
 	 	 	 	 	 b u f f e r . s l i c e ( 0 ,   l a s t L i n e L e n g t h   -   1 ) , 
 	 	 	 	 	 h a n d l e T r a i l i n g C h a r a c t e r s ( 
 	 	 	 	 	 	 b u f f e r . s l i c e ( l a s t L i n e L e n g t h   -   1 ,   l a s t L i n e L e n g t h ) 
 	 	 	 	 	 ) 
 	 	 	 	 ) ; 
 	 	 	 } 
 	 	 } 
 
 	 	 / /   ` Q u o t e d - P r i n t a b l e `   u s e s   C R L F . 
 	 	 r e t u r n   r e s u l t . j o i n ( ' = \ r \ n ' ) ; 
 	 } ; 
 
 	 v a r   q u o t e d P r i n t a b l e   =   { 
 	 	 ' e n c o d e ' :   e n c o d e , 
 	 	 ' d e c o d e ' :   d e c o d e , 
 	 	 ' v e r s i o n ' :   ' < % =   v e r s i o n   % > ' 
 	 } ; 
 
 	 / /   S o m e   A M D   b u i l d   o p t i m i z e r s ,   l i k e   r . j s ,   c h e c k   f o r   s p e c i f i c   c o n d i t i o n   p a t t e r n s 
 	 / /   l i k e   t h e   f o l l o w i n g : 
 	 i f   ( 
 	 	 t y p e o f   d e f i n e   = =   ' f u n c t i o n '   & & 
 	 	 t y p e o f   d e f i n e . a m d   = =   ' o b j e c t '   & & 
 	 	 d e f i n e . a m d 
 	 )   { 
 	 	 d e f i n e ( f u n c t i o n ( )   { 
 	 	 	 r e t u r n   q u o t e d P r i n t a b l e ; 
 	 	 } ) ; 
 	 } 	 e l s e   i f   ( f r e e E x p o r t s   & &   ! f r e e E x p o r t s . n o d e T y p e )   { 
 	 	 i f   ( f r e e M o d u l e )   {   / /   i n   N o d e . j s ,   i o . j s ,   o r   R i n g o J S   v 0 . 8 . 0 + 
 	 	 	 f r e e M o d u l e . e x p o r t s   =   q u o t e d P r i n t a b l e ; 
 	 	 }   e l s e   {   / /   i n   N a r w h a l   o r   R i n g o J S   v 0 . 7 . 0 - 
 	 	 	 f o r   ( v a r   k e y   i n   q u o t e d P r i n t a b l e )   { 
 	 	 	 	 q u o t e d P r i n t a b l e . h a s O w n P r o p e r t y ( k e y )   & &   ( f r e e E x p o r t s [ k e y ]   =   q u o t e d P r i n t a b l e [ k e y ] ) ; 
 	 	 	 } 
 	 	 } 
 	 }   e l s e   {   / /   i n   R h i n o   o r   a   w e b   b r o w s e r 
 	 	 r o o t . q u o t e d P r i n t a b l e   =   q u o t e d P r i n t a b l e ; 
 	 } 
 
 } ( t h i s ) ) ; 
 
 / * !   h t t p s : / / m t h s . b e / u t f 8 j s   v 3 . 0 . 0   b y   @ m a t h i a s   * / 
 ; ( f u n c t i o n ( r o o t )   { 
 
 	 v a r   s t r i n g F r o m C h a r C o d e   =   S t r i n g . f r o m C h a r C o d e ; 
 
 	 / /   T a k e n   f r o m   h t t p s : / / m t h s . b e / p u n y c o d e 
 	 f u n c t i o n   u c s 2 d e c o d e ( s t r i n g )   { 
 	 	 v a r   o u t p u t   =   [ ] ; 
 	 	 v a r   c o u n t e r   =   0 ; 
 	 	 v a r   l e n g t h   =   s t r i n g . l e n g t h ; 
 	 	 v a r   v a l u e ; 
 	 	 v a r   e x t r a ; 
 	 	 w h i l e   ( c o u n t e r   <   l e n g t h )   { 
 	 	 	 v a l u e   =   s t r i n g . c h a r C o d e A t ( c o u n t e r + + ) ; 
 	 	 	 i f   ( v a l u e   > =   0 x D 8 0 0   & &   v a l u e   < =   0 x D B F F   & &   c o u n t e r   <   l e n g t h )   { 
 	 	 	 	 / /   h i g h   s u r r o g a t e ,   a n d   t h e r e   i s   a   n e x t   c h a r a c t e r 
 	 	 	 	 e x t r a   =   s t r i n g . c h a r C o d e A t ( c o u n t e r + + ) ; 
 	 	 	 	 i f   ( ( e x t r a   &   0 x F C 0 0 )   = =   0 x D C 0 0 )   {   / /   l o w   s u r r o g a t e 
 	 	 	 	 	 o u t p u t . p u s h ( ( ( v a l u e   &   0 x 3 F F )   < <   1 0 )   +   ( e x t r a   &   0 x 3 F F )   +   0 x 1 0 0 0 0 ) ; 
 	 	 	 	 }   e l s e   { 
 	 	 	 	 	 / /   u n m a t c h e d   s u r r o g a t e ;   o n l y   a p p e n d   t h i s   c o d e   u n i t ,   i n   c a s e   t h e   n e x t 
 	 	 	 	 	 / /   c o d e   u n i t   i s   t h e   h i g h   s u r r o g a t e   o f   a   s u r r o g a t e   p a i r 
 	 	 	 	 	 o u t p u t . p u s h ( v a l u e ) ; 
 	 	 	 	 	 c o u n t e r - - ; 
 	 	 	 	 } 
 	 	 	 }   e l s e   { 
 	 	 	 	 o u t p u t . p u s h ( v a l u e ) ; 
 	 	 	 } 
 	 	 } 
 	 	 r e t u r n   o u t p u t ; 
 	 } 
 
 	 / /   T a k e n   f r o m   h t t p s : / / m t h s . b e / p u n y c o d e 
 	 f u n c t i o n   u c s 2 e n c o d e ( a r r a y )   { 
 	 	 v a r   l e n g t h   =   a r r a y . l e n g t h ; 
 	 	 v a r   i n d e x   =   - 1 ; 
 	 	 v a r   v a l u e ; 
 	 	 v a r   o u t p u t   =   ' ' ; 
 	 	 w h i l e   ( + + i n d e x   <   l e n g t h )   { 
 	 	 	 v a l u e   =   a r r a y [ i n d e x ] ; 
 	 	 	 i f   ( v a l u e   >   0 x F F F F )   { 
 	 	 	 	 v a l u e   - =   0 x 1 0 0 0 0 ; 
 	 	 	 	 o u t p u t   + =   s t r i n g F r o m C h a r C o d e ( v a l u e   > > >   1 0   &   0 x 3 F F   |   0 x D 8 0 0 ) ; 
 	 	 	 	 v a l u e   =   0 x D C 0 0   |   v a l u e   &   0 x 3 F F ; 
 	 	 	 } 
 	 	 	 o u t p u t   + =   s t r i n g F r o m C h a r C o d e ( v a l u e ) ; 
 	 	 } 
 	 	 r e t u r n   o u t p u t ; 
 	 } 
 
 	 f u n c t i o n   c h e c k S c a l a r V a l u e ( c o d e P o i n t )   { 
 	 	 i f   ( c o d e P o i n t   > =   0 x D 8 0 0   & &   c o d e P o i n t   < =   0 x D F F F )   { 
 	 	 	 t h r o w   E r r o r ( 
 	 	 	 	 ' L o n e   s u r r o g a t e   U + '   +   c o d e P o i n t . t o S t r i n g ( 1 6 ) . t o U p p e r C a s e ( )   + 
 	 	 	 	 '   i s   n o t   a   s c a l a r   v a l u e ' 
 	 	 	 ) ; 
 	 	 } 
 	 } 
 	 / * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - * / 
 
 	 f u n c t i o n   c r e a t e B y t e ( c o d e P o i n t ,   s h i f t )   { 
 	 	 r e t u r n   s t r i n g F r o m C h a r C o d e ( ( ( c o d e P o i n t   > >   s h i f t )   &   0 x 3 F )   |   0 x 8 0 ) ; 
 	 } 
 
 	 f u n c t i o n   e n c o d e C o d e P o i n t ( c o d e P o i n t )   { 
 	 	 i f   ( ( c o d e P o i n t   &   0 x F F F F F F 8 0 )   = =   0 )   {   / /   1 - b y t e   s e q u e n c e 
 	 	 	 r e t u r n   s t r i n g F r o m C h a r C o d e ( c o d e P o i n t ) ; 
 	 	 } 
 	 	 v a r   s y m b o l   =   ' ' ; 
 	 	 i f   ( ( c o d e P o i n t   &   0 x F F F F F 8 0 0 )   = =   0 )   {   / /   2 - b y t e   s e q u e n c e 
 	 	 	 s y m b o l   =   s t r i n g F r o m C h a r C o d e ( ( ( c o d e P o i n t   > >   6 )   &   0 x 1 F )   |   0 x C 0 ) ; 
 	 	 } 
 	 	 e l s e   i f   ( ( c o d e P o i n t   &   0 x F F F F 0 0 0 0 )   = =   0 )   {   / /   3 - b y t e   s e q u e n c e 
 	 	 	 c h e c k S c a l a r V a l u e ( c o d e P o i n t ) ; 
 	 	 	 s y m b o l   =   s t r i n g F r o m C h a r C o d e ( ( ( c o d e P o i n t   > >   1 2 )   &   0 x 0 F )   |   0 x E 0 ) ; 
 	 	 	 s y m b o l   + =   c r e a t e B y t e ( c o d e P o i n t ,   6 ) ; 
 	 	 } 
 	 	 e l s e   i f   ( ( c o d e P o i n t   &   0 x F F E 0 0 0 0 0 )   = =   0 )   {   / /   4 - b y t e   s e q u e n c e 
 	 	 	 s y m b o l   =   s t r i n g F r o m C h a r C o d e ( ( ( c o d e P o i n t   > >   1 8 )   &   0 x 0 7 )   |   0 x F 0 ) ; 
 	 	 	 s y m b o l   + =   c r e a t e B y t e ( c o d e P o i n t ,   1 2 ) ; 
 	 	 	 s y m b o l   + =   c r e a t e B y t e ( c o d e P o i n t ,   6 ) ; 
 	 	 } 
 	 	 s y m b o l   + =   s t r i n g F r o m C h a r C o d e ( ( c o d e P o i n t   &   0 x 3 F )   |   0 x 8 0 ) ; 
 	 	 r e t u r n   s y m b o l ; 
 	 } 
 
 	 f u n c t i o n   u t f 8 e n c o d e ( s t r i n g )   { 
 	 	 v a r   c o d e P o i n t s   =   u c s 2 d e c o d e ( s t r i n g ) ; 
 	 	 v a r   l e n g t h   =   c o d e P o i n t s . l e n g t h ; 
 	 	 v a r   i n d e x   =   - 1 ; 
 	 	 v a r   c o d e P o i n t ; 
 	 	 v a r   b y t e S t r i n g   =   ' ' ; 
 	 	 w h i l e   ( + + i n d e x   <   l e n g t h )   { 
 	 	 	 c o d e P o i n t   =   c o d e P o i n t s [ i n d e x ] ; 
 	 	 	 b y t e S t r i n g   + =   e n c o d e C o d e P o i n t ( c o d e P o i n t ) ; 
 	 	 } 
 	 	 r e t u r n   b y t e S t r i n g ; 
 	 } 
 
 	 / * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - * / 
 
 	 f u n c t i o n   r e a d C o n t i n u a t i o n B y t e ( )   { 
 	 	 i f   ( b y t e I n d e x   > =   b y t e C o u n t )   { 
 	 	 	 t h r o w   E r r o r ( ' I n v a l i d   b y t e   i n d e x ' ) ; 
 	 	 } 
 
 	 	 v a r   c o n t i n u a t i o n B y t e   =   b y t e A r r a y [ b y t e I n d e x ]   &   0 x F F ; 
 	 	 b y t e I n d e x + + ; 
 
 	 	 i f   ( ( c o n t i n u a t i o n B y t e   &   0 x C 0 )   = =   0 x 8 0 )   { 
 	 	 	 r e t u r n   c o n t i n u a t i o n B y t e   &   0 x 3 F ; 
 	 	 } 
 
 	 	 / /   I f   w e   e n d   u p   h e r e ,   i t  s   n o t   a   c o n t i n u a t i o n   b y t e 
 	 	 t h r o w   E r r o r ( ' I n v a l i d   c o n t i n u a t i o n   b y t e ' ) ; 
 	 } 
 
 	 f u n c t i o n   d e c o d e S y m b o l ( )   { 
 	 	 v a r   b y t e 1 ; 
 	 	 v a r   b y t e 2 ; 
 	 	 v a r   b y t e 3 ; 
 	 	 v a r   b y t e 4 ; 
 	 	 v a r   c o d e P o i n t ; 
 
 	 	 i f   ( b y t e I n d e x   >   b y t e C o u n t )   { 
 	 	 	 t h r o w   E r r o r ( ' I n v a l i d   b y t e   i n d e x ' ) ; 
 	 	 } 
 
 	 	 i f   ( b y t e I n d e x   = =   b y t e C o u n t )   { 
 	 	 	 r e t u r n   f a l s e ; 
 	 	 } 
 
 	 	 / /   R e a d   f i r s t   b y t e 
 	 	 b y t e 1   =   b y t e A r r a y [ b y t e I n d e x ]   &   0 x F F ; 
 	 	 b y t e I n d e x + + ; 
 
 	 	 / /   1 - b y t e   s e q u e n c e   ( n o   c o n t i n u a t i o n   b y t e s ) 
 	 	 i f   ( ( b y t e 1   &   0 x 8 0 )   = =   0 )   { 
 	 	 	 r e t u r n   b y t e 1 ; 
 	 	 } 
 
 	 	 / /   2 - b y t e   s e q u e n c e 
 	 	 i f   ( ( b y t e 1   &   0 x E 0 )   = =   0 x C 0 )   { 
 	 	 	 b y t e 2   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 c o d e P o i n t   =   ( ( b y t e 1   &   0 x 1 F )   < <   6 )   |   b y t e 2 ; 
 	 	 	 i f   ( c o d e P o i n t   > =   0 x 8 0 )   { 
 	 	 	 	 r e t u r n   c o d e P o i n t ; 
 	 	 	 }   e l s e   { 
 	 	 	 	 t h r o w   E r r o r ( ' I n v a l i d   c o n t i n u a t i o n   b y t e ' ) ; 
 	 	 	 } 
 	 	 } 
 
 	 	 / /   3 - b y t e   s e q u e n c e   ( m a y   i n c l u d e   u n p a i r e d   s u r r o g a t e s ) 
 	 	 i f   ( ( b y t e 1   &   0 x F 0 )   = =   0 x E 0 )   { 
 	 	 	 b y t e 2   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 b y t e 3   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 c o d e P o i n t   =   ( ( b y t e 1   &   0 x 0 F )   < <   1 2 )   |   ( b y t e 2   < <   6 )   |   b y t e 3 ; 
 	 	 	 i f   ( c o d e P o i n t   > =   0 x 0 8 0 0 )   { 
 	 	 	 	 c h e c k S c a l a r V a l u e ( c o d e P o i n t ) ; 
 	 	 	 	 r e t u r n   c o d e P o i n t ; 
 	 	 	 }   e l s e   { 
 	 	 	 	 t h r o w   E r r o r ( ' I n v a l i d   c o n t i n u a t i o n   b y t e ' ) ; 
 	 	 	 } 
 	 	 } 
 
 	 	 / /   4 - b y t e   s e q u e n c e 
 	 	 i f   ( ( b y t e 1   &   0 x F 8 )   = =   0 x F 0 )   { 
 	 	 	 b y t e 2   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 b y t e 3   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 b y t e 4   =   r e a d C o n t i n u a t i o n B y t e ( ) ; 
 	 	 	 c o d e P o i n t   =   ( ( b y t e 1   &   0 x 0 7 )   < <   0 x 1 2 )   |   ( b y t e 2   < <   0 x 0 C )   | 
 	 	 	 	 ( b y t e 3   < <   0 x 0 6 )   |   b y t e 4 ; 
 	 	 	 i f   ( c o d e P o i n t   > =   0 x 0 1 0 0 0 0   & &   c o d e P o i n t   < =   0 x 1 0 F F F F )   { 
 	 	 	 	 r e t u r n   c o d e P o i n t ; 
 	 	 	 } 
 	 	 } 
 
 	 	 t h r o w   E r r o r ( ' I n v a l i d   U T F - 8   d e t e c t e d ' ) ; 
 	 } 
 
 	 v a r   b y t e A r r a y ; 
 	 v a r   b y t e C o u n t ; 
 	 v a r   b y t e I n d e x ; 
 	 f u n c t i o n   u t f 8 d e c o d e ( b y t e S t r i n g )   { 
 	 	 b y t e A r r a y   =   u c s 2 d e c o d e ( b y t e S t r i n g ) ; 
 	 	 b y t e C o u n t   =   b y t e A r r a y . l e n g t h ; 
 	 	 b y t e I n d e x   =   0 ; 
 	 	 v a r   c o d e P o i n t s   =   [ ] ; 
 	 	 v a r   t m p ; 
 	 	 w h i l e   ( ( t m p   =   d e c o d e S y m b o l ( ) )   ! = =   f a l s e )   { 
 	 	 	 c o d e P o i n t s . p u s h ( t m p ) ; 
 	 	 } 
 	 	 r e t u r n   u c s 2 e n c o d e ( c o d e P o i n t s ) ; 
 	 } 
 
 	 / * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - * / 
 
 	 r o o t . v e r s i o n   =   ' 3 . 0 . 0 ' ; 
 	 r o o t . e n c o d e   =   u t f 8 e n c o d e ; 
 	 r o o t . d e c o d e   =   u t f 8 d e c o d e ; 
 
 } ( t y p e o f   e x p o r t s   = = =   ' u n d e f i n e d '   ?   t h i s . u t f 8   =   { }   :   e x p o r t s ) ) ;                              Y�jscr  ��ޭ