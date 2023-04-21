import 'package:flutter/material.dart';
import 'drag_widget.dart';

class Popup {

  static OverlayEntry? entry;

  static showPopupWindow({
    required BuildContext context,
    required Widget Function(VoidCallback closeFunc) child,
    double? width,
    double? height,
    Offset? offset,
    BorderRadius? borderRadius,
    bool isDarkBackground = true,
    String? title,
    VoidCallback? onSubmit,
    Widget? submitWidget,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {


    if (entry != null) {
      return;
    }
    entry = OverlayEntry(builder: (BuildContext context) {
      return DragArea(
        isAllowDrag: true,
          backgroundColor: isDarkBackground ? const Color(0x7F000000) : null,
          closeFun: () {
            if (entry != null) {
              entry?.remove();
              entry = null;
            }
          },
          initOffset: offset ??
              (width != null && height != null
                  ? Offset(MediaQuery.of(context).size.width * 0.5 - width / 2,
                  MediaQuery.of(context).size.height * 0.5 - height / 2)
                  : null),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius:
              borderRadius ?? const BorderRadius.all(Radius.circular(5)),
              color:   const Color(0xFFffffff),
              border: isDarkBackground
                  ? Border.all(
                width: 2,
                color:
                  const Color(0xFFbebebe),
              )
                  : null,
              boxShadow: isDarkBackground
                  ? null
                  : const [
                BoxShadow(
                  color: Color(0xFFbebebe),
                  offset: Offset(3, 3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                if (title != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0x00f5f6f7),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 18,
                              color:
                                  Color(0xFF444444)),
                        ),
                        InkWell(
                          onTap: () {
                            if (onSubmit != null) {
                              onSubmit();
                            }
                            entry?.remove();
                            entry = null;
                          },
                          child: onSubmit != null
                              ? (submitWidget ?? const Icon(Icons.check))
                              : const Icon(Icons.close),
                        )
                      ],
                    ),
                  ),
                if (title != null)
                  SizedBox(
                    height: 1,
                    child: Container(
                      color:  const Color(0xFFE5E6E9),
                    ),
                  ),
                if (height != null && width != null)
                  Expanded(child: child(() {
                    entry?.remove();
                    entry = null;
                  })),
                if (height == null || width == null)
                  child(() {
                    entry?.remove();
                    entry = null;
                  }),
                if (onCancel != null || onConfirm != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onCancel != null)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: OutlinedButton(
                                onPressed: () {
                                  entry?.remove();
                                  entry = null;
                                  onCancel();
                                },
                                child: const Text(
                                   "取消" ,
                                  style: TextStyle(
                                      color:
                                        Colors.black),
                                )),
                          ),
                        if (onConfirm != null)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: ElevatedButton(
                                onPressed: () {
                                  entry?.remove();
                                  entry = null;
                                  onConfirm();
                                },
                                child: const Text(
                                   "确定" ,
                                  style: TextStyle(color: Colors.black),
                                )),
                          ),
                      ],
                    ),
                  )
              ],
            ),
          ));
    });
    Overlay.of(context).insert(entry!);

  }

}