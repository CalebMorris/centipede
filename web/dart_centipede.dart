import 'dart:html';
import 'dart:math';
import 'dart:async';

/*      
        Centipeed
  Simple game that you collect food and grow until there is no more room.
  End Condition: All body blocks have two adjacent blocks
  Bodysection size = 8px
  Border = 4px
*/

void main() {
  CanvasElement canvas = query("#myCanvas");
  canvas.focus();
  var centipede = new Game(canvas);
  centipede.init();
}

num fpsAverage;

void showFps(num fps) {
  if (fpsAverage == null) {
    fpsAverage = fps;
  }

  fpsAverage = fps * 0.05 + fpsAverage * 0.95;

  query("#notes").text = "${fpsAverage.round().toInt()} fps";
}

void update_Mouse( num x, num y ) {
  query("#mouse").text = "(${x.round().toInt()},${y.round().toInt()})";
}

class Game {
  CanvasElement canvas;
  num renderTime;
  
  num _width; num _height;
  num mx; num my;
  
  var max_cells;
  var body;
  var current_food;
  var game_timer;
  String direction;
  bool game_running;
  bool game_success;
  Cell head;
  num speed;
  num cell_size;
  num fill;
  num growth_rate;
  num growth_remaining;
  
  Game(this.canvas){
    this.canvas.onKeyDown.listen(key_listener);
    this.canvas.onMouseMove.listen(mouse_movement);
    this.canvas.onMouseDown.listen(mouse_press);
    this.canvas.onMouseUp.listen(mouse_release);
    
    init_var();
  }
  
  void init_var() {
    _width = canvas.width;
    _height = canvas.height;
    cell_size = 8;
    speed = 100;
    max_cells = [(_width/cell_size).toInt(),
                 (_height/cell_size).toInt()];
    head = new Cell(_width/cell_size/2, _height/cell_size/2, cell_size);
    body = [head];
    growth_rate = 4;
    growth_remaining = 0;
    switch(new Random().nextInt(4)) {
      case 0:
        direction = "North";
        break;
      case 1:
        direction = "South";
        break;
      case 2:
        direction = "East";
        break;
      default:
        direction = "West";
    }
    get_next_food();
    game_success = false;
    game_running = true;
  }
  
  void mouse_movement( e ) {
    getMouse(e);
    update_Mouse(mx, my);
  }
  
  void mouse_press( e ) {
    var context = this.canvas.context2D;
    if( !game_running ) {
      if( mx>_width/4+4 && mx<(_width/4+4+_width/2-8) &&
          my>_height*5/12+8 && my<(_height*5/12+4+_height/4-16)) {
        print("Button Pressed");
        if( game_success ) {
          context.clearRect(_width/4, _height/6, _width/2, _height/2);
          context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
          context.clearRect(_width/4+10, _height*5/12+10, _width/2-20, _height/4-20);
          context.font = '30pt Calibri';
          context.textAlign = 'center';
          context.fillText("Success", _width/2, _height/4, _width/2);
          context.font = '20pt Calibri';
          context.textAlign = 'center';
          context.fillText("New Game", _width/2, _height/2+4, _width/2);
        }
        else {
          context.clearRect(_width/4, _height/6, _width/2, _height/2);
          context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
          context.clearRect(_width/4+10, _height*5/12+10, _width/2-20, _height/4-20);
          context.font = '30pt Calibri';
          context.textAlign = 'center';
          context.fillText("Failure", _width/2, _height/4, _width/2);
          context.font = '20pt Calibri';
          context.textAlign = 'center';
          context.fillText("Restart", _width/2, _height/2+4, _width/2);
        }
      }
    }
  }
  
  void mouse_release( e ) {
    var context = this.canvas.context2D;
    if( !game_running ) {
      if( mx>_width/4+4 && mx<(_width/4+4+_width/2-8) &&
          my>_height*5/12+8 && my<(_height*5/12+4+_height/4-16)) {
        print("Button Released");
        if( game_success ) {
          context.clearRect(_width/4, _height/6, _width/2, _height/2);
          context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
          context.clearRect(_width/4+8, _height*5/12+8, _width/2-16, _height/4-16);
          context.font = '30pt Calibri';
          context.textAlign = 'center';
          context.fillText("Success", _width/2, _height/4, _width/2);
          context.font = '20pt Calibri';
          context.textAlign = 'center';
          context.fillText("New Game", _width/2, _height/2, _width/2);
        }
        else{
          context.clearRect(_width/4, _height/6, _width/2, _height/2);
          context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
          context.clearRect(_width/4+8, _height*5/12+8, _width/2-16, _height/4-16);
          context.font = '30pt Calibri';
          context.textAlign = 'center';
          context.fillText("Failure", _width/2, _height/4, _width/2);
          context.font = '20pt Calibri';
          context.textAlign = 'center';
          context.fillText("Restart", _width/2, _height/2, _width/2);
        }
        init_var();
        init();
      }
    }
  }
  
  void getMouse(e) {
    mx = _width + e.clientX - canvas.getBoundingClientRect().right;
    my = _height + e.clientY - canvas.getBoundingClientRect().bottom;
  }
  
  void key_listener( e ) {
    switch( e.keyCode ) {
      case 37:
        change_direction("West");
        //print("West");
        break;
      case 38:
        change_direction("North");
        //print("North");
        break;
      case 39:
        change_direction("East");
        //print("East");
        break;
      case 40:
        change_direction("South");
        //print("South");
        break;
    }
  }
  
  void get_next_food() {
    //TODO do check if position in body
    var rnd = new Random(new DateTime.now().millisecondsSinceEpoch);
    num first = rnd.nextInt(max_cells[0]);
    num second = rnd.nextInt(max_cells[1]);
    current_food = new Food(first, second, cell_size);
  }
  
  void init() {
    clear_screen();
    step();
    requestRedraw();
  }
  
  void clear_screen() {
    var context = canvas.context2D;
    context.fillStyle = 'black';
    context.fillRect(0, 0, _width, _height);
  }
  
  void step() {
    //Move along the current direction from the head of the snake
    var next_position = new Cell.nextPosition(head, direction);
    //print("Next: $next_position");
    //print("Body: $body");
    if( next_position.x > max_cells[0] || next_position.y > max_cells[1] ||
        next_position.x < 0 || next_position.y < 0) {
      game_over();
    }
    if( current_food.compareTo(next_position)==0 ) {
      growth_remaining += growth_rate;
      get_next_food();
    }
    if( growth_remaining < 1 ) {
      body.removeLast();
    }
    else {
      growth_remaining--;
    }
    for( var i = 0; i < body.length; ++i ) {
      if( next_position.equal(body[i]) ) {
        game_over();
      }
    }
    body.insert(0,next_position);
    head = body[0];
    if( game_running ) {
      game_timer = new Timer(new Duration(milliseconds:speed), step);
    }
  }
  
  void game_over() {
    game_running = false;
    if( game_success ) {
      game_timer = new Timer(new Duration(milliseconds:speed), draw_success);
    }
    else {
      game_timer = new Timer(new Duration(milliseconds:speed), draw_failure);
    }
  }
  
  void change_direction(String direction) {
    this.direction = direction;
  }
  
  void draw_failure() {
    var context = this.canvas.context2D;
    context.clearRect(_width/4, _height/6, _width/2, _height/2);
    context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
    context.clearRect(_width/4+8, _height*5/12+8, _width/2-16, _height/4-16);
    context.font = '30pt Calibri';
    context.textAlign = 'center';
    context.fillText("Failure", _width/2, _height/4, _width/2);
    context.font = '20pt Calibri';
    context.textAlign = 'center';
    context.fillText("Restart", _width/2, _height/2, _width/2);
  }
  
  void draw_success() {
    var context = this.canvas.context2D;
    context.clearRect(_width/4, _height/6, _width/2, _height/2);
    context.fillRect(_width/4+4, _height*5/12+4, _width/2-8, _height/4-8);
    context.clearRect(_width/4+8, _height*5/12+8, _width/2-16, _height/4-16);
    context.font = '30pt Calibri';
    context.textAlign = 'center';
    context.fillText("Success", _width/2, _height/4, _width/2);
    context.font = '20pt Calibri';
    context.textAlign = 'center';
    context.fillText("New Game", _width/2, _height/2, _width/2);
  }
  
  void draw(num _) {
    var context = canvas.context2D;
    
    num time = new DateTime.now().millisecondsSinceEpoch;

    if (renderTime != null) {
      showFps((1000 / (time - renderTime)).round());
    }
    
    renderTime = time;
    
    clear_screen();
    current_food.draw(context);
    for( var i = 0; i < body.length; ++i ) {
      body[i].draw(context);
    }
    if( game_running ) {
      requestRedraw();
    }
  }
  
  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}

class Cell {
  num x;
  num y;
  num body_size;
  Cell(this.x,this.y,this.body_size) {}
  Cell.nextPosition(Cell current,String direction) {
    this.body_size = current.body_size;
    switch(direction) {
      case 'North':
        this.x = current.x;
        this.y = current.y-1;
        break;
      case 'South':
        this.x = current.x;
        this.y = current.y+1;
        break;
      case 'East':
        this.x = current.x+1;
        this.y = current.y;
        break;
      case 'West':
        this.x = current.x-1;
        this.y = current.y;
        break;
    }
  }
  void draw(CanvasRenderingContext2D context) {
    if( x+body_size < 0 || x-body_size >= context.canvas.width ) {
      return;
    }
    if( y+body_size < 0 || y-body_size >= context.canvas.height ) {
      return;
    }
    context.clearRect(x*body_size, y*body_size, body_size, body_size);
  }
  bool equal(Cell other) {
    if( this.x == other.x && this.y == other.y ) {
      return true;
    }
    return false;
  }
  bool equalFromCoord(num x, num y) {
    if( this.x == x && this.y == y ) {
      return true;
    }
    return false;
  }
  String toString() {
    return "(" +x.toString()+ "," +y.toString()+ ")";
  }
}

class Food {
  num x;
  num y;
  num body_size;
  Food(this.x,this.y,this.body_size) {}
  int compareTo(Cell cell) {
    if( this.x == cell.x && this.y == cell.y ) {
      return 0;
    }
    else {
      return -1;
    }
  }
  void draw(CanvasRenderingContext2D context) {
    if( x+body_size < 0 || x-body_size >= context.canvas.width ) {
      return;
    }
    if( y+body_size < 0 || y-body_size >= context.canvas.height ) {
      return;
    }
    context.save();
    context.beginPath();
    context.arc(x*body_size+body_size/2,y*body_size+body_size/2,body_size/2,0,PI*2);
    context.closePath();
    context.clip();
    context.clearRect(x*body_size, y*body_size, body_size, body_size);
    context.restore();
  }
}