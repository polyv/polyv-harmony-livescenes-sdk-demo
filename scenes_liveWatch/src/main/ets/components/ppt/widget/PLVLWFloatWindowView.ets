import { PLVCallback, PLVCustomBuilder } from '@polyvharmony/live-scenes-sdk'
import { MutableObserver, watchStates, Rect } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'
import { curves } from '@kit.ArkUI'

export const FLOATING_WINDOW_INIT_POSITION_TOP = 360 // 初始位置
export const FLOATING_WINDOW_INIT_POSITION_PADDING = 0 // 初始位置

@Component
export struct PLVLWFloatWindowView {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @BuilderParam contentBuilder: (PLVCallback) = PLVCustomBuilder
  @Link edges: Edges
  @Link containerWidth: number
  @Link containerHeight: number
  @Link floatingWindowVisibility: Visibility
  @Link floatingWindowWidth: number
  @Link floatingWindowHeight: number
  @Prop @Watch('onRatio') floatingWindowAspectRatio: number = -1
  @State floatingWindowBorderRadius: Length | BorderRadiuses = 8
  @State enableHorizontalMove: boolean = true
  onClickEvent: PLVCallback | undefined
  onTouchEvent: PLVCallback<TouchEvent> | undefined
  onAreaChangeEvent: PLVCallback<Rect> | undefined
  private newArea?: Area
  private windowStartX: number = 0
  private windowStartY: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value ?? true
      if (isPortrait) {
        this.edges.top = FLOATING_WINDOW_INIT_POSITION_TOP
        this.edges.right = FLOATING_WINDOW_INIT_POSITION_PADDING
      } else {
        this.edges.top = FLOATING_WINDOW_INIT_POSITION_TOP / 2
        this.edges.right = FLOATING_WINDOW_INIT_POSITION_PADDING
      }
    }).pushTo(this.observers)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Stack() {
      this.contentBuilder()
    }
    .clip(true)
    .borderRadius(this.floatingWindowBorderRadius)
    .aspectRatio(this.floatingWindowAspectRatio)
    .width(this.floatingWindowWidth)
    .height(this.floatingWindowHeight)
    .visibility(this.floatingWindowVisibility)
    .position(this.edges)
    .onAreaChange((oldValue, newValue: Area) => {
      this.newArea = newValue
      this.postAreaChanged()
    })
    .onClick(() => {
      this.onClickEvent?.()
    })
    .onTouch((event: TouchEvent) => {
      this.onTouchEvent?.(event)
      this.handleOnTouch(event)
    })
  }

  handleOnTouch(event: TouchEvent): void {
    switch (event.type) {
      case TouchType.Down: {
        this.windowStartX = event.touches[0].windowX;
        this.windowStartY = event.touches[0].windowY;
        break;
      }
      case TouchType.Move: {
        const windowX: number = event.touches[0].windowX;
        const windowY: number = event.touches[0].windowY;
        animateTo({ curve: curves.responsiveSpringMotion() }, () => {
          if (this.enableHorizontalMove) {
            this.edges.right = this.edges.right as number - (windowX - this.windowStartX);
          }
          this.edges.top = this.edges.top as number + (windowY - this.windowStartY);
          this.windowStartX = windowX;
          this.windowStartY = windowY;
        })
        break;
      }
      case TouchType.Cancel:
      case TouchType.Up: {
        animateTo({ curve: curves.springMotion() }, () => {
          this.checkRightEdges()
          this.checkTopEdges()
          this.postAreaChanged()
        })
        break;
      }
      default: {
        break;
      }
    }
  }

  checkRightEdges() {
    if (this.edges.right as number < FLOATING_WINDOW_INIT_POSITION_PADDING) {
      this.edges.right = FLOATING_WINDOW_INIT_POSITION_PADDING
    } else if (this.edges.right as number > this.containerWidth - this.floatingWindowWidth - FLOATING_WINDOW_INIT_POSITION_PADDING) {
      this.edges.right = this.containerWidth - this.floatingWindowWidth - FLOATING_WINDOW_INIT_POSITION_PADDING
    }
  }

  checkTopEdges() {
    if (this.edges.top as number < FLOATING_WINDOW_INIT_POSITION_PADDING) {
      this.edges.top = FLOATING_WINDOW_INIT_POSITION_PADDING;
    } else if (this.edges.top as number > this.containerHeight - this.realFloatingWindowHeight() - FLOATING_WINDOW_INIT_POSITION_PADDING) {
      this.edges.top = this.containerHeight - this.realFloatingWindowHeight() - FLOATING_WINDOW_INIT_POSITION_PADDING
    }
  }

  realFloatingWindowHeight() {
    return this.floatingWindowAspectRatio !== -1 ? this.floatingWindowWidth / this.floatingWindowAspectRatio : this.floatingWindowHeight
  }

  postAreaChanged() {
    if (this.newArea) {
      const left = this.containerWidth - this.floatingWindowWidth - (this.edges.right as number)
      const top = this.edges.top as number
      this.onAreaChangeEvent?.(new Rect({
        left: left,
        top: top,
        right: this.newArea.width as number + left,
        bottom: this.newArea.height as number + top
      }))
    }
  }

  onRatio() {
    this.checkTopEdges()
  }
}