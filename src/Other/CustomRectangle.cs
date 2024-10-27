using System;
using System.Diagnostics.CodeAnalysis;
using System.Management.Automation.Host;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

/// <summary>
/// Represents a rectangular region of the screen.
/// <!--We use this structure instead of System.Drawing.Rectangle because S.D.R
/// is way overkill and would bring in another assembly.-->
/// </summary>
[SuppressMessage("ReSharper", "MemberCanBePrivate.Global")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public struct CustomRectangle {
  /// <summary>Gets and sets the left side of the rectangle.</summary>
  public int Left { get; set; }

  /// <summary>Gets and sets the top of the rectangle.</summary>
  public int Top { get; set; }

  /// <summary>Gets and sets the right side of the rectangle.</summary>
  public int Right { get; set; }

  /// <summary>Gets and sets the bottom of the rectangle.</summary>
  public int Bottom { get; set; }

  /// <summary>
  /// Initialize a new instance of the Rectangle class and defines the Left, Top, Right, and Bottom values.
  /// </summary>
  /// <param name="left">The left side of the rectangle</param>
  /// <param name="top">The top of the rectangle</param>
  /// <param name="right">The right side of the rectangle</param>
  /// <param name="bottom">The bottom of the rectangle</param>
  /// <exception cref="T:System.ArgumentException">
  /// <paramref name="right" /> is less than <paramref name="left" />;
  /// <paramref name="bottom" /> is less than <paramref name="top" />
  /// </exception>
  public CustomRectangle(int left, int top, int right, int bottom) {
    this.Left = left;
    this.Top = top;
    this.Right = right;
    this.Bottom = bottom;
  }

  /// <summary>
  /// Initializes a new instance of the Rectangle class and defines the Left, Top, Right, and Bottom values
  /// by <paramref name="upperLeft" />, the upper left corner and <paramref name="lowerRight" />, the lower
  /// right corner.
  /// <!--
  /// Added based on feedback from review with BCL PM.
  /// -->
  /// </summary>
  /// <param name="upperLeft">
  /// The Coordinates of the upper left corner of the Rectangle
  /// </param>
  /// <param name="lowerRight">
  /// The Coordinates of the lower right corner of the Rectangle
  /// </param>
  /// <exception />
  public CustomRectangle(Coordinates upperLeft, Coordinates lowerRight) {
    this.Left = upperLeft.X;
    this.Top = upperLeft.Y;
    this.Right = lowerRight.X;
    this.Bottom = lowerRight.Y;
  }

  /// <summary>
  /// Initializes a new instance of the Rectangle class and defines the Left, Top, Right, and Bottom values
  /// by <paramref name="upperLeft" />, the upper left corner and <paramref name="lowerRight" />, the lower
  /// right corner.
  /// <!--
  /// Added based on feedback from review with BCL PM.
  /// -->
  /// </summary>
  /// <param name="upperLeft">
  /// The Coordinates of the upper left corner of the Rectangle
  /// </param>
  /// <param name="lowerRight">
  /// The Coordinates of the lower right corner of the Rectangle
  /// </param>
  /// <exception />
  public CustomRectangle(Coordinates upperLeft, Size size) {
    this.Left = upperLeft.X;
    this.Top = upperLeft.Y;
    this.Right = upperLeft.X + size.Width;
    this.Bottom = upperLeft.Y + size.Height;
  }

  /// <summary>
  /// Overloads <see cref="M:System.Object.ToString" />
  /// </summary>
  /// <returns>
  /// "a,b ; c,d" where a, b, c, and d are values of the Left, Top, Right, and Bottom properties.
  /// </returns>
  public readonly override string ToString() {
    return $"{this.Left},{this.Top} ; {this.Right},{this.Bottom}";
  }

  /// <summary>
  /// Overrides <see cref="M:System.Object.Equals(System.Object)" />
  /// </summary>
  /// <param name="customRectangle">rectangle to be compared for equality.</param>
  /// <returns>
  /// True if <paramref name="customRectangle" /> is Rectangle and its Left, Top, Right, and Bottom values are the same as those of this instance,
  /// false if not.
  /// </returns>
  public readonly bool Equals(CustomRectangle customRectangle) {
    return customRectangle.Top.Equals(this.Top) &&
           customRectangle.Top.Equals(this.Left) &&
           customRectangle.Top.Equals(this.Right) &&
           customRectangle.Top.Equals(this.Bottom);
  }

  /// <summary>
  /// Overrides <see cref="M:System.Object.Equals(System.Object)" />
  /// </summary>
  /// <param name="rectangle">rectangle to be compared for equality.</param>
  /// <returns>
  /// True if <paramref name="rectangle" /> is Rectangle and its Left, Top, Right, and Bottom values are the same as those of this instance,
  /// false if not.
  /// </returns>
  public readonly bool Equals(Rectangle rectangle) {
    return rectangle.Top.Equals(this.Top) &&
           rectangle.Top.Equals(this.Left) &&
           rectangle.Top.Equals(this.Right) &&
           rectangle.Top.Equals(this.Bottom);
  }

  /// <summary>
  /// Overrides <see cref="M:System.Object.Equals(System.Object)" />
  /// </summary>
  /// <param name="obj">object to be compared for equality.</param>
  /// <returns>
  /// True if <paramref name="obj" /> is Rectangle and its Left, Top, Right, and Bottom values are the same as those of this instance,
  /// false if not.
  /// </returns>
  public readonly override bool Equals(object? obj) {
    if (obj is CustomRectangle customRectangle) {
      return this.Equals(customRectangle);
    }

    if (obj is Rectangle rectangle) {
      return this.Equals(rectangle);
    }

    return false;
  }

  /// <summary>
  /// Overrides <see cref="M:System.Object.GetHashCode" />
  /// </summary>
  /// <returns>
  /// Hash code for this instance.
  /// <!-- consider (Top XOR Bottom) the high-order part of a 64-bit int,
  ///                (Left XOR Right) the lower order half.  Then use the int64.GetHashCode.-->
  /// </returns>
  /// <exception />
  public readonly override int GetHashCode() {
    return HashCode.Combine(this.Top ^ this.Bottom, this.Left ^ this.Right);
  }

  /// <summary>Compares two instances for equality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if the respective Top, Left, Bottom, and Right fields are the same, false otherwise.
  /// </returns>
  public static bool operator ==(CustomRectangle first, CustomRectangle second) {
    return first.Equals(second);
  }

  /// <summary>Compares two instances for equality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if the respective Top, Left, Bottom, and Right fields are the same, false otherwise.
  /// </returns>
  public static bool operator ==(CustomRectangle first, object? second) {
    return first.Equals(second);
  }

  /// <summary>Compares two instances for equality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if the respective Top, Left, Bottom, and Right fields are the same, false otherwise.
  /// </returns>
  public static bool operator ==(CustomRectangle first, Rectangle second) {
    return first.Equals(second);
  }

  /// <summary>Compares two instances for inequality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if any of the respective Top, Left, Bottom, and Right fields are not the same, false otherwise.
  /// </returns>
  /// <exception />
  public static bool operator !=(CustomRectangle first, CustomRectangle second) {
    return !first.Equals(second);
  }

  /// <summary>Compares two instances for inequality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if any of the respective Top, Left, Bottom, and Right fields are not the same, false otherwise.
  /// </returns>
  /// <exception />
  public static bool operator !=(CustomRectangle first, Rectangle second) {
    return !first.Equals(second);
  }

  /// <summary>Compares two instances for inequality.</summary>
  /// <param name="first">The left side operand.</param>
  /// <param name="second">The right side operand.</param>
  /// <returns>
  /// true if any of the respective Top, Left, Bottom, and Right fields are not the same, false otherwise.
  /// </returns>
  /// <exception />
  public static bool operator !=(CustomRectangle first, object? second) {
    return !first.Equals(second);
  }

  public readonly Size Size => new(this.Left - this.Right, this.Top - this.Bottom);

  public readonly int Width => this.Size.Width;

  public readonly int Height => this.Size.Height;

  public readonly Coordinates Start => new(this.Left, this.Top);
  public readonly Coordinates End => new(this.Right, this.Bottom);
}