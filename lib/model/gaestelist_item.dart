import 'package:four_secrets_wedding_app/data/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ignore: must_be_immutable
class GaestelistItem extends StatefulWidget {
  final String guestName;
  bool canceled;
  bool mayBeTakePart;
  bool takePart;
  final Function(BuildContext)? deleteFunction;
  final Function(dynamic)? statusChanged;

  GaestelistItem({
    super.key,
    required this.guestName,
    required this.takePart,
    required this.mayBeTakePart,
    required this.canceled,
    required this.deleteFunction,
    required this.statusChanged,
  });

  @override
  State<GaestelistItem> createState() => _GaestelistItemState();
}

class _GaestelistItemState extends State<GaestelistItem> {
  final double padValue = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 25),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: widget.deleteFunction,
              icon: FontAwesomeIcons.trashCan,
              backgroundColor: Colors.red.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade300,
              ],
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    widget.statusChanged!(States.takePart.name);
                  });
                },
                child: this.widget.takePart == false
                    ? Icon(Icons.check_box_outline_blank_rounded)
                    : Icon(
                        Icons.check_box_outlined,
                        color: Colors.green,
                      ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    widget.statusChanged!(States.mayBeTakePart.name);
                  });
                },
                child: this.widget.mayBeTakePart == false
                    ? Icon(Icons.check_box_outline_blank_rounded)
                    : Icon(
                        Icons.check_box_outlined,
                        color: Colors.amber,
                      ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    widget.statusChanged!(States.canceled.name);
                  });
                },
                child: this.widget.canceled == false
                    ? Icon(Icons.check_box_outline_blank_rounded)
                    : Icon(
                        Icons.check_box_outlined,
                        color: Colors.red,
                      ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 7.5),
              ),
              Expanded(
                child: Container(
                  width: 165,
                  child: Text(
                    this.widget.guestName,
                    overflow: TextOverflow.fade,
                    softWrap: true,
                    style: TextStyle(
                      decoration: widget.canceled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 3,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 20 / 2),
                child: Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  color: Colors.grey[600],
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
